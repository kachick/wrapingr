# Copyright (C) 2012 Kenichi Kamiya

require 'striuct'

module MSWindows

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