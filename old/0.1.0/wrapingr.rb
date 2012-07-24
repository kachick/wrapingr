#!/usr/bin/local/ruby -w

# Wrapper for "ping -r" on Windows XP/Vista

# Copyright (C) 2012  Kenichi Kamiya
# Usage: this.rb [IP or Hostname] [interval_seconds<Float]>
# Requirements: ruby-1.9.3p194

require 'striuct'
require 'csv'

CSV_HEADERS = %w[Time Summary Changed! 1 2 3 4 5 6 7 8 9 Rest]

CSVRow = Striuct.define {
  member :time, Time
  member :summary, String
  member :changed, BOOLEAN?
  member :route1, String
  member :route2, String
  member :route3, String
  member :route4, String
  member :route5, String
  member :route6, String
  member :route7, String
  member :route8, String
  member :route9, String
  member :rest, String
  
  def routes
    1.upto(9).map{|n|self[:"route#{n}"]}
  end
  
  def ftime
    time.strftime '%Y-%m-%d_%H-%M-%S~%L'
  end
}

def csv_row_for(cmd_output, last)
  CSVRow.new.tap {|row|
    row.time = Time.now

    source = cmd_output.dup
    source.slice!(/^Pinging.+:\n/)
    row.summary = source.slice!(/^(?:Reply|Request).+$/)
    source.slice!(/\n+/)
    source.slice!(/^Ping statistics.*?\n/)

    1.upto 9 do |i|
      if source.slice!(/^\s+(?:Route:)?\s*(\S+)\s*(?:->)?\s*$/)
        row[:"route#{i}"] = $1
      end
    end

    unless source.empty?
      row.rest = source.gsub("\n", '\n')
    end
    
    row.changed = last ? (row.routes != last.routes) : false
  }
end

def switch_dos_charset!(type)
  num = {ascii: 437, shiftjis: 932}[type] || raise(ArgumentError)

  `chcp #{num}`
end

unless (1..2).cover? ARGV.length
   abort 'usage: this.rb [IP or Hostname] [interval_seconds<Float]>'
end

dst = ARGV.shift
interval = (f = ARGV.shift) ? Float(f) : 0.2

path_prefix = "#{$PROGRAM_NAME}.#{Time.now.strftime '%Y-%m-%d_%H-%M-%S'}_#{dst}"
switch_dos_charset! :ascii
command = "ping -r 9 -w 100 -n 1 -l 1400 -4 #{dst}"
separator = '-' * 78

File.open "#{path_prefix}.pure.txt", 'w' do |pure|
  pure.puts "command: #{command}", separator
  CSV.open "#{path_prefix}.summary.csv", 'w', write_headers: true, headers: CSV_HEADERS do |csv|

    $stderr.puts 'Stop with [ctrl + C]'
    
    last_row = nil
    loop do
      result = `#{command}`
      
      row = csv_row_for result, last_row
      last_row = row
      
      csv << [row.ftime, row.summary, row.changed, *row.routes, row.rest]
      
      header = "# #{row.ftime} #{row.changed ? '!' : nil}"
      
      pure.puts header, result, separator
      puts header
      puts row.routes.join(' -> ')
      
      sleep interval
    end
  end
end
