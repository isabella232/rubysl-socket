module RubySL
  module Socket
    module Foreign
      class SockaddrIn < Rubinius::FFI::Struct
        config("rbx.platform.sockaddr_in",
               :sin_family, :sin_port, :sin_addr, :sin_zero)

        def self.with_sockaddr(addr)
          pointer = Rubinius::FFI::MemoryPointer.new(addr.bytesize)
          pointer.write_string(addr, addr.bytesize)

          new(pointer)
        end

        def family
          self[:sin_family]
        end

        def to_s
          pointer.read_string(pointer.total)
        end
      end
    end
  end
end
