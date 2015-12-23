module RubySL
  module Socket
    module Foreign
      class Ifaddrs < Rubinius::FFI::Struct
        config("rbx.platform.ifaddrs", :ifa_next, :ifa_name, :ifa_flags,
               :ifa_addr, :ifa_netmask)

        def next
          self[:ifa_next]
        end

        def address
          self[:ifa_addr]
        end

        def to_sockaddr
          Sockaddr.new(address)
        end

        def to_sockaddr_in
          SockaddrIn.new(address)
        end

        def to_sockaddr_in6
          SockaddrIn6.new(address)
        end
      end
    end
  end
end
