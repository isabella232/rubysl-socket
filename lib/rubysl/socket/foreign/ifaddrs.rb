module RubySL
  module Socket
    module Foreign
      class Ifaddrs < Rubinius::FFI::Struct
        config("rbx.platform.ifaddrs", :ifa_next, :ifa_name, :ifa_flags,
               :ifa_addr, :ifa_netmask)
      end
    end
  end
end
