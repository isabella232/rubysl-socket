module RubySL
  module Socket
    module Foreign
      class Sockaddr_Un < Rubinius::FFI::Struct
        config('rbx.platform.sockaddr_un', :sun_family, :sun_path)

        def self.with_sockaddr(addr)
          if addr.bytesize > size
            raise ArgumentError,
              "UNIX socket path is too long (max: #{size} bytes)"
          end

          pointer = Rubinius::FFI::MemoryPointer.new(size)
          pointer.write_string(addr, addr.bytesize)

          new(pointer)
        end

        def to_s
          pointer.read_string(pointer.total)
        end
      end
    end
  end
end
