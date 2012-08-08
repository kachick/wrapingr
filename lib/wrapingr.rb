# Copyright (C) 2012 Kenichi Kamiya

require 'csv'
require_relative 'mswindows'

module Wrapingr

  include MSWindows
  
  CSV_OPTIONS = {
    write_headers: true,
    headers: %w[Time Pass? RouteChanged? 1 2 3 4 5 6 7 8 9 Summary Rest]
  }.freeze
  
  VERSION = '0.2.1'.freeze

  # @param [String] dest_addr
  # @param [Numeric] interval
  def run(dest_addr, interval)
    $stderr.puts 'Stop with [ctrl + C]'

    path_prefix = "#{$PROGRAM_NAME}.#{Time.now.strftime '%Y-%m-%d_%H-%M-%S'}_#{dest_addr}"
    
    CommandPrompt.open do |cmd|
      cmd.width = 120

      command = "ping -r 9 -w 100 -n 1 -l 1400 -4 #{dest_addr}"
      separator = '-' * (cmd.width - 2)
      last, last_passed, route_changed = nil, nil, false

      File.open "#{path_prefix}.log", 'w' do |log|
        announce = "# Command: #{command}\n# Interval: #{interval} sec", separator
        log.puts announce
        puts announce

        CSV.open "#{path_prefix}.csv", 'w', CSV_OPTIONS do |csv|

          loop do
            time, cmd_output = Time.now, `#{command}`
            ftime = ftime time
            last = result = Ping::RecordRoute.parse cmd_output

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
      
    end
    
  end

  private

  # @return [String] e.g "2012-06-18 01:23:45,678"
  def ftime(time)
    time.strftime '%Y-%m-%d %H:%M:%S,%L'
  end

  module_function :run, :ftime

end
