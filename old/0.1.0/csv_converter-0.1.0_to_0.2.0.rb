$VERBOSE = true

abort 'usage: this.rb foo.csv [bar.csv]' unless ARGV.length >= 1

require 'csv'

CONVERTED_OPTIONS = {
  write_headers: true, 
  headers: %w[Time Replied RouteChanged 1 2 3 4 5 6 7 8 9 Summary Rest]
}

ARGV.each do |path|
  original = CSV.read path, headers: :first_row

  CSV.open "#{path}.converted.csv", 'w', CONVERTED_OPTIONS do |converted|
    last_replied_routes = nil
    
    original.each do |row|
      routes = [
        row['1'], row['2'], row['3'], row['4'], row['5'],
        row['6'], row['7'], row['8'], row['9']
      ]
      
      if row['1']
        replied = true
        route_changed = (routes != last_replied_routes)
        last_replied_routes = routes
      else
        replied = false
        route_changed = false
      end

      converted << [
        row['Time'],
        replied,
        route_changed,
        *row.fields(*%w[1 2 3 4 5 6 7 8 9 Summary Rest])
      ]
    end
  end
end