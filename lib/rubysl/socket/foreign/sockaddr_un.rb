module RubySL
  module Socket
    module Foreign
      # If we have the details to support unix sockets, do so.
      if Rubinius::FFI.config("sockaddr_un.sun_family.offset") and
        ::Socket::Constants.const_defined?(:AF_UNIX)
        class Sockaddr_Un < Rubinius::FFI::Struct
          config("rbx.platform.sockaddr_un", :sun_family, :sun_path)

          def initialize(filename = nil)
            maxfnsize = self.size -
              (Rubinius::FFI.config("sockaddr_un.sun_family.size") + 1)

            if filename and filename.length > maxfnsize
              raise ArgumentError,
                "too long unix socket path (max: #{maxfnsize}bytes)"
            end

            @p = Rubinius::FFI::MemoryPointer.new self.size

            if filename
              @p.write_string( [::Socket::AF_UNIX].pack("s") + filename )
            end

            super(@p)
          end

          def to_s
            @p.read_string self.size
          end
        end
      end
    end
  end
end
