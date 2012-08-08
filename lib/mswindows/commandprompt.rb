# Copyright (C) 2012 Kenichi Kamiya

module MSWindows

  class CommandPrompt
  
    CHAR_SETS = {
      ascii: 437,
      shiftjis: 932
    }.freeze
    
    class << self
      
      # @return [CommandPrompt]
      def open
        instance = new
        first_charset = instance.charset

        begin
          instance.charset = :ascii
          first_widh = instance.width
          yield instance
        ensure
          instance.width = first_widh
          instance.charset = first_charset
          instance
        end
      end
      
    end

    # @return [Integer]
    def width
      raise 'Invalid charset' unless charset == :ascii
      Integer `mode con /status`.slice(/\bColumns:\s*(\d+)/, 1)
    end

    # @param [Integer] size
    # @return [Integer] size
    def width=(size)
      `mode con cols=#{size}`
      size
    end

    # @return [Integer]
    def codepage
      Integer `mode con cp /status`.slice(/:\s*(\d+)/, 1)
    end

    # @param [Integer] integer
    # @return [Integer] integer
    def codepage=(integer)
      `chcp #{integer}`
      integer
    end
    
    # @return [Symbol]
    def charset
      charset_for codepage
    end

    # @param [Symbol] type
    def charset=(type)
      self.codepage = CHAR_SETS.fetch(type)
    end
    
    # @param [Integer] cp
    # @return [Symbol]
    def charset_for(cp)
      CHAR_SETS.key(cp) || raise(ArgumentError)
    end

  end

end