module RubySL
  module Socket
    module Foreign
      class Ifaddrs < Rubinius::FFI::Struct
        config("rbx.platform.ifaddrs", :ifa_next, :ifa_name, :ifa_flags,
               :ifa_addr, :ifa_netmask, :ifa_broadaddr, :ifa_dstaddr)

        def name
          self[:ifa_name]
        end

        def flags
          self[:ifa_flags]
        end

        def next
          self[:ifa_next]
        end

        def address
          self[:ifa_addr]
        end

        def broadcast_address
          self[:ifa_broadaddr]
        end

        def destination_address
          self[:ifa_dstaddr]
        end

        def netmask_address
          self[:ifa_netmask]
        end

        def broadcast?
          flags & ::Socket::IFF_BROADCAST > 0
        end

        def point_to_point?
          flags & ::Socket::IFF_POINTOPOINT > 0
        end

        def address_to_addrinfo
          return unless address

          sockaddr = Sockaddr.new(address)

          if sockaddr.family == ::Socket::AF_INET
            ::Addrinfo.new(SockaddrIn.new(address).to_s)
          elsif sockaddr.family == ::Socket::AF_INET6
            ::Addrinfo.new(SockaddrIn6.new(address).to_s)
          else
            nil
          end
        end

        def broadcast_to_addrinfo
          return if !broadcast? || !broadcast_address

          ::Addrinfo.raw_with_family(Sockaddr.new(broadcast_address).family)
        end

        def destination_to_addrinfo
          return if !point_to_point? || !destination_address

          ::Addrinfo.raw_with_family(Sockaddr.new(destination_address).family)
        end

        def netmask_to_addrinfo
          return unless netmask_address

          sockaddr = Sockaddr.new(netmask_address)

          if sockaddr.family == ::Socket::AF_INET
            ::Addrinfo.new(SockaddrIn.new(netmask_address).to_s)
          elsif sockaddr.family == ::Socket::AF_INET6
            ::Addrinfo.new(SockaddrIn6.new(netmask_address).to_s)
          else
            ::Addrinfo.raw_with_family(sockaddr.family)
          end
        end
      end
    end
  end
end
