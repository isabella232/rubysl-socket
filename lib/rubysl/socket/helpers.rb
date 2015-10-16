module RubySL
  module Socket
    # Helper methods re-used between Socket and Addrinfo that don't really
    # belong to just either one of those classes.
    module Helpers
      def self.address_family(family)
        case family
        when Symbol, String
          f = family.to_s
          if f[0..2] != 'AF_'
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

      def self.protocol_family(family)
        case family
        when Symbol, String
          f = family.to_s
          if f[0..2] != 'PF_'
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
    end
  end
end
