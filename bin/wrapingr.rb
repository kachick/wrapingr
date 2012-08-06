# wrapingr
#   Wrapper for "ping -r" on Windows XP/Vista

# Copyright (C) 2012 Kenichi Kamiya
# Usage: this.rb [IP or Hostname] [interval_seconds<Float]>
# Version: 0.2.0
# Requirements:
#   * ruby-1.9.3p194
#   * striuct-0.3.0

$VERBOSE = true

require 'striuct'
require 'csv'

module MSWindows

  module CommandPrompt
    module_function
    
    def change_width!(size)
      `mode con cols=#{size}`
    end
    
    def change_charset!(type)
      num = {ascii: 437, shiftjis: 932}[type] || raise(ArgumentError)

      `chcp #{num}`
    end

  end

  module Ping

    class RecordRoute < Striuct

      class << self
        
        def parse(str)
          define {|pr|
            source = str.dup
            source.slice!(/^Pinging.+:\n/)
            pr.summary = source.slice!(/^((?:Reply|Request|Destination).+)\n/, 1)
            source.slice!(/\n+/)
            source.slice!(/^Ping statistics.*?\n/)
            
            1.upto 9 do |i|
              pr[:"route#{i}"] = (
                if source.slice!(/^\s+(?:Route:)?\s*(\S+)\s*(?:->)?\s*$/)
                  $1
                else
                  nil
                end
              )
            end
            
            unless source.empty?
              pr.rest = source.gsub("\n", '\n')
            end
          }
        end

      end
      
      member :summary, String
      member :route1, OR(nil, String)
      member :route2, OR(nil, String)
      member :route3, OR(nil, String)
      member :route4, OR(nil, String)
      member :route5, OR(nil, String)
      member :route6, OR(nil, String)
      member :route7, OR(nil, String)
      member :route8, OR(nil, String)
      member :route9, OR(nil, String)
      member :rest, OR(nil, String)
      close_member

      def hops
        1.upto(9).map{|n|self[:"route#{n}"]}
      end
      
      alias_method :route, :hops
      
      def pass?
        !!route1
      end

    end

  end

end


include MSWindows

unless (1..2).cover? ARGV.length
  abort 'usage: this.rb [IP or Hostname] [interval_seconds<Float]>'
end


$stderr.puts 'Stop with [ctrl + C]'

# @return [String] e.g "2012-06-18 01:23:45,678"
def ftime(time)
  time.strftime '%Y-%m-%d %H:%M:%S,%L'
end

dst = ARGV.shift
interval = (f = ARGV.shift) ? Float(f) : 1.0

path_prefix = "#{$PROGRAM_NAME}.#{Time.now.strftime '%Y-%m-%d_%H-%M-%S'}_#{dst}"
width = 120
CommandPrompt.change_width! width
CommandPrompt.change_charset! :ascii

CSV_OPTIONS = {
  write_headers: true,
  headers: %w[Time Pass? RouteChanged? 1 2 3 4 5 6 7 8 9 Summary Rest]
}.freeze

command = "ping -r 9 -w 100 -n 1 -l 1400 -4 #{dst}"
separator = '-' * (width - 2)
last, last_passed, route_changed = nil, nil, false

File.open "#{path_prefix}.log", 'w' do |log|
  announce = "# Command: #{command}\n# Interval: #{interval} sec", separator
  log.puts announce
  puts announce

  CSV.open "#{path_prefix}.csv", 'w', CSV_OPTIONS do |csv|

    loop do
      time, cmd_output = Time.now, `#{command}`
      ftime = ftime time
      last = result = MSWindows::Ping::RecordRoute.parse cmd_output

      if result.pass?
        if last_passed
          route_changed = (result.route != last_passed.route)
        end
        
        last_passed = result
      else
        route_changed = false
      end
      
      header = "# #{ftime} #{result.pass? ? (route_changed ? 'Change!' : 'OK') : 'NG'}"
      log.puts header, cmd_output, separator
      
      route_summaries = result.route.each_with_index.map{|addr, i|"#{i + 1}: #{addr.to_s.ljust(15)}"}
      puts(
           header,
           route_summaries[0..3].join(' -> '),
           route_summaries[4..9].join(' -> ')
           )

      csv << [ftime, result.pass?, route_changed, *result.route, result.summary, result.rest]
  
      sleep interval
    end

  end
end