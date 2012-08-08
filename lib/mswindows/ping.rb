# Copyright (C) 2012 Kenichi Kamiya

require 'striuct'

module MSWindows

  module Ping

    class MalformedDataError < TypeError; end

    class RecordRoute < Striuct

      class << self
        
        # @param [String] str
        # @return [RecordRoute]
        def parse(str)
          define {|pr|
            source = str.dup
            if source.slice!(/^Pinging.+:\n/)
              unless pr.summary = source.slice!(/^((?:Reply|Request|Destination).+)\n/, 1)
                raise MalformedDataError
              end
            else
              raise MalformedDataError
            end
            
            source.slice!(/\n+/)      
            
            if source.slice!(/^Approximate round trip.*?\n+\s*Minimum = (\d+)ms, Maximum = (\d+)ms, Average = (\d+)ms.*?\n?/)
              pr.round_trip_min, pr.round_trip_max, pr.round_trip_ave = $1.to_i, $2.to_i, $3.to_i
            else
              raise MalformedDataError
            end
            
            if source.slice!(/^Ping statistics.*?\n+\s*Packets: Sent = (\d+), Received = (\d+), Lost = (\d+).+loss.+\n?/)
              pr.sent_count, pr.recived_count = $1.to_i, $2.to_i
              raise MalformedDataError unless pr.lost_count == $3.to_i
            else
              raise MalformedDataError
            end

            1.upto 9 do |i|
              pr[:"route#{i}"] = (
                if source.slice!(/^\s+(?:Route:)?\s*(\S+)\s*(?:->)?\s*$/)
                  $1
                else
                  nil
                end
              )
            end
            
            pr.rest = source.empty? ? nil : source.strip.gsub("\n", '\n')
          }
        end

      end
      
      member :summary, String
      member :sent_count, Integer
      member :recived_count, Integer
      member :route1, OR(nil, String)
      member :route2, OR(nil, String)
      member :route3, OR(nil, String)
      member :route4, OR(nil, String)
      member :route5, OR(nil, String)
      member :route6, OR(nil, String)
      member :route7, OR(nil, String)
      member :route8, OR(nil, String)
      member :route9, OR(nil, String)
      member :round_trip_min, Integer
      member :round_trip_max, Integer
      member :round_trip_ave, Integer
      member :rest, OR(nil, String)
      close_member
      
      # @return [Integer]
      def lost_count
        sent_count - recived_count
      end

      # @return [Array<String>]
      def hops
        1.upto(9).map{|n|self[:"route#{n}"]}
      end
      
      alias_method :route, :hops
      
      def pass?
        lost_count == 0
      end

    end

  end

end