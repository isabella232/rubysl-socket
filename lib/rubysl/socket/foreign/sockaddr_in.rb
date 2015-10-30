module RubySL
  module Socket
    module Foreign
      class Sockaddr_In < Rubinius::FFI::Struct
        config("rbx.platform.sockaddr_in",
               :sin_family, :sin_port, :sin_addr, :sin_zero)

        def initialize(sockaddrin)
          @p = Rubinius::FFI::MemoryPointer.new sockaddrin.bytesize

          @p.write_string(sockaddrin, sockaddrin.bytesize)

          super(@p)
        end

        def to_s
          @p.read_string(@p.total)
        end
      end
    end
  end
end
