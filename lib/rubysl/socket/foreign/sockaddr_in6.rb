module RubySL
  module Socket
    module Foreign
      class Sockaddr_In6 < Rubinius::FFI::Struct
        config("rbx.platform.sockaddr_in6", :sin6_family, :sin6_port,
               :sin6_flowinfo, :sin6_addr, :sin6_scope_id)
      end
    end
  end
end
