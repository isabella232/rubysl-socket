module RubySL
  module Socket
    module Foreign
      class Sockaddr < Rubinius::FFI::Struct
        config("rbx.platform.sockaddr", :sa_data, :sa_family)
      end
    end
  end
end
