module RubySL
  module Socket
    module Foreign
      class Sockaddr < Rubinius::FFI::Struct
        config("rbx.platform.sockaddr", :sa_data, :sa_family)

        def family
          self[:sa_family]
        end

        def to_s
          pointer.read_string(pointer.total)
        end
      end
    end
  end
end
