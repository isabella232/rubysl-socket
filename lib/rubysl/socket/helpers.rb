module RubySL
  module Socket
    # Helper methods re-used between Socket and Addrinfo that don't really
    # belong to just either one of those classes.
    module Helpers
      def self.coerce_to_string(object)
        if object.is_a?(String) or object.is_a?(Symbol)
          object.to_s
        elsif object.respond_to?(:to_str)
          Rubinius::Type.coerce_to(object, String, :to_str)
        else
          raise TypeError, "no implicit conversion of #{object.inspect} into Integer"
        end
      end

      def self.family_prefix?(family)
        family.start_with?('AF_') || family.start_with?('PF_')
      end

      def self.prefix_with(name, prefix)
        unless name.start_with?(prefix)
          name = "#{prefix}#{name}"
        end

        name
      end

      def self.prefixed_socket_constant(name, prefix, &block)
        prefixed = prefix_with(name, prefix)

        socket_constant(prefixed, &block)
      end

      def self.socket_constant(name)
        if ::Socket.const_defined?(name)
          ::Socket.const_get(name)
        else
          raise SocketError, yield
        end
      end

      def self.address_family(family)
        case family
        when Symbol, String
          f = family.to_s

          unless family_prefix?(f)
            f = 'AF_' + f
          end

          if ::Socket.const_defined?(f)
            ::Socket.const_get(f)
          else
            raise SocketError, "unknown socket domain: #{family}"
          end
        when Integer
          family
        when NilClass
          ::Socket::AF_UNSPEC
        else
          if family.respond_to?(:to_str)
            address_family(Rubinius::Type.coerce_to(family, String, :to_str))
          else
            raise SocketError, "unknown socket domain: #{family}"
          end
        end
      end

      def self.address_family_name(family_int)
        # Since this list doesn't change very often (if ever) we're using a
        # plain old "case" instead of something like Socket.constants.grep(...)
        case family_int
        when ::Socket::AF_APPLETALK
          'AF_APPLETALK'
        when ::Socket::AF_AX25
          'AF_AX25'
        when ::Socket::AF_INET
          'AF_INET'
        when ::Socket::AF_INET6
          'AF_INET6'
        when ::Socket::AF_IPX
          'AF_IPX'
        when ::Socket::AF_ISDN
          'AF_ISDN'
        when ::Socket::AF_LOCAL
          'AF_LOCAL'
        when ::Socket::AF_MAX
          'AF_MAX'
        when ::Socket::AF_PACKET
          'AF_PACKET'
        when ::Socket::AF_ROUTE
          'AF_ROUTE'
        when ::Socket::AF_SNA
          'AF_SNA'
        when ::Socket::AF_UNIX
          'AF_UNIX'
        else
          'AF_UNSPEC'
        end
      end

      def self.protocol_family_name(family_int)
        ::Socket.constants.grep(/^PF_/).each do |name|
          return name.to_s if ::Socket.const_get(name) == family_int
        end

        'PF_UNSPEC'
      end

      def self.protocol_name(family_int)
        ::Socket.constants.grep(/^IPPROTO_/).each do |name|
          return name.to_s if ::Socket.const_get(name) == family_int
        end

        'IPPROTO_IP'
      end

      def self.socket_type_name(socktype)
        case socktype
        when ::Socket::SOCK_DGRAM
          'SOCK_DGRAM'
        when ::Socket::SOCK_PACKET
          'SOCK_PACKET'
        when ::Socket::SOCK_RAW
          'SOCK_RAW'
        when ::Socket::SOCK_RDM
          'SOCK_RDM'
        when ::Socket::SOCK_SEQPACKET
          'SOCK_SEQPACKET'
        when ::Socket::SOCK_STREAM
          'SOCK_STREAM'
        end
      end

      def self.protocol_family(family)
        case family
        when Symbol, String
          f = family.to_s

          unless family_prefix?(f)
            f = 'PF_' + f
          end

          if ::Socket.const_defined?(f)
            ::Socket.const_get(f)
          else
            raise SocketError, "unknown socket domain: #{family}"
          end
        when Integer
          family
        when NilClass
          ::Socket::PF_UNSPEC
        else
          if family.respond_to?(:to_str)
            protocol_family(Rubinius::Type.coerce_to(family, String, :to_str))
          else
            raise SocketError, "unknown socket domain: #{family}"
          end
        end
      end

      def self.socket_type(type)
        case type
        when Symbol, String
          t = type.to_s

          if t[0..4] != 'SOCK_'
            t = "SOCK_#{t}"
          end

          if ::Socket.const_defined?(t)
            ::Socket.const_get(t)
          else
            raise SocketError, "unknown socket type: #{type}"
          end
        when Integer
          type
        when NilClass
          0
        else
          if type.respond_to?(:to_str)
            socket_type(Rubinius::Type.coerce_to(type, String, :to_str))
          else
            raise SocketError, "unknown socket type: #{type}"
          end
        end
      end

      def self.convert_reverse_lookup(socket = nil, reverse_lookup = nil)
        if reverse_lookup.nil?
          if socket
            reverse_lookup = !socket.do_not_reverse_lookup
          else
            reverse_lookup = !BasicSocket.do_not_reverse_lookup
          end

        elsif reverse_lookup == :hostname
          reverse_lookup = true

        elsif reverse_lookup == :numeric
          reverse_lookup = false

        elsif reverse_lookup != true and reverse_lookup != false
          raise ArgumentError,
            "invalid reverse_lookup flag: #{reverse_lookup.inspect}"
        end

        reverse_lookup
      end

      def self.address_info(method, socket, reverse_lookup = nil)
        sockaddr = Foreign.__send__(method, socket.descriptor)

        reverse_lookup = convert_reverse_lookup(socket, reverse_lookup)

        options = ::Socket::Constants::NI_NUMERICHOST |
          ::Socket::Constants::NI_NUMERICSERV

        family, port, host, ip = Foreign
          .getnameinfo(sockaddr, options, reverse_lookup)

        [family, port.to_i, host, ip]
      end

      def self.shutdown_option(how)
        case how
        when String, Symbol
          prefixed_socket_constant(how.to_s, 'SHUT_') do
            "unknown shutdown argument: #{how}"
          end
        when Fixnum
          if how == ::Socket::SHUT_RD or
            how == ::Socket::SHUT_WR or
            how == ::Socket::SHUT_RDWR
            how
          else
            raise ArgumentError,
              'argument should be :SHUT_RD, :SHUT_WR, or :SHUT_RDWR'
          end
        else
          if how.respond_to?(:to_str)
            shutdown_option(coerce_to_string(how))
          else
            raise TypeError,
              "no implicit conversion of #{how.class} into Integer"
          end
        end
      end
    end
  end
end
