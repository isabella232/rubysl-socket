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
      @level = level_arg(@family, level)
      @level_name = level
      @optname = optname_arg(@level, optname)
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

    private

    def level_arg(family, level)
      case level
      when Symbol, String
        if Socket::Constants.const_defined?(level)
          Socket::Constants.const_get(level)
        else
          if is_ip_family?(family)
            ip_level_to_int(level)
          else
            unknown_level_to_int(level)
          end
        end
      when Integer
        level
      else
        raise SocketError, "unknown protocol level: #{level}"
      end
    rescue NameError
      raise SocketError, "unknown protocol level: #{level}"
    end

    def optname_arg(level, optname)
      case optname
      when Symbol, String
        if Socket::Constants.const_defined?(optname)
          Socket::Constants.const_get(optname)
        else
          case(level)
          when Socket::Constants::SOL_SOCKET
            constant("SO", optname)
          when Socket::Constants::IPPROTO_IP
            constant("IP", optname)
          when Socket::Constants::IPPROTO_TCP
            constant("TCP", optname)
          when Socket::Constants::IPPROTO_UDP
            constant("UDP", optname)
          else
            if Socket::Constants.const_defined?(Socket::Constants::IPPROTO_IPV6) &&
                level == Socket::Constants::IPPROTO_IPV6
              constant("IPV6", optname)
            else
              optname
            end
          end
        end
      else
        optname
      end
    rescue NameError
      raise SocketError, "unknown socket level option name: #{optname}"
    end

    def is_ip_family?(family)
      [Socket::AF_INET, Socket::AF_INET6].include? family
    end

    def ip_level_to_int(level)
      prefixes = ["IPPROTO", "SOL"]
      prefixes.each do |prefix|
        if Socket::Constants.const_defined?("#{prefix}_#{level}")
          return Socket::Constants.const_get("#{prefix}_#{level}")
        end
      end
    end

    def unknown_level_to_int(level)
      constant("SOL", level)
    end

    def constant(prefix, suffix)
      #if Socket::Constants.const_defined?("#{prefix}_#{suffix}")
        Socket::Constants.const_get("#{prefix}_#{suffix}")
      #end
    end
  end
end
