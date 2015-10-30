class Socket < BasicSocket
  class Option
    attr_reader :family, :level, :optname, :data

    def self.bool(family, level, optname, bool)
      data = [(bool ? 1 : 0)].pack('i')
      new family, level, optname, data
    end

    def self.int(family, level, optname, integer)
      new family, level, optname, [integer].pack('i')
    end

    def self.linger(onoff, secs)
      linger = RubySL::Socket::Foreign::Linger.new

      case onoff
      when Integer
        linger[:l_onoff] = onoff
      else
        linger[:l_onoff] = onoff ? 1 : 0
      end
      linger[:l_linger] = secs

      p = linger.to_ptr
      data = p.read_string(p.total)

      new :UNSPEC, :SOCKET, :LINGER, data
    end

    def initialize(family, level, optname, data)
      @family = RubySL::Socket::Helpers.address_family(family)
      @family_name = family
      @level = RubySL::Socket::SocketOptions.socket_level(level, @family)
      @level_name = level
      @optname = RubySL::Socket::SocketOptions.socket_option(@level, optname)
      @opt_name = optname
      @data = data
    end

    def unpack(template)
      @data.unpack template
    end

    def inspect
      "#<#{self.class}: #@family_name #@level_name #@opt_name #{@data.inspect}>"
    end

    def bool
      unless @data.length == Rubinius::FFI.type_size(:int)
        raise TypeError, "size differ. expected as sizeof(int)=" +
          "#{Rubinius::FFI.type_size(:int)} but #{@data.length}"
      end

      i = @data.unpack('i').first
      i == 0 ? false : true
    end

    def int
      unless @data.length == Rubinius::FFI.type_size(:int)
        raise TypeError, "size differ. expected as sizeof(int)=" +
          "#{Rubinius::FFI.type_size(:int)} but #{@data.length}"
      end
      @data.unpack('i').first
    end

    def linger
      if @level != Socket::SOL_SOCKET || @optname != Socket::SO_LINGER
        raise TypeError, "linger socket option expected"
      end
      if @data.bytesize != Rubinius::FFI.config("linger.sizeof")
        raise TypeError, "size differ. expected as sizeof(struct linger)=" +
          "#{Rubinius::FFI.config("linger.sizeof")} but #{@data.length}"
      end

      linger = RubySL::Socket::Foreign::Linger.new
      linger.to_ptr.write_string @data, @data.bytesize

      onoff = nil
      case linger[:l_onoff]
      when 0 then onoff = false
      when 1 then onoff = true
      else onoff = linger[:l_onoff].to_i
      end

      [onoff, linger[:l_linger].to_i]
    end

    alias :to_s :data
  end
end
