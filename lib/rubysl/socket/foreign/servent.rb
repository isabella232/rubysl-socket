module RubySL
  module Socket
    module Foreign
      class Servent < Rubinius::FFI::Struct
        config('rbx.platform.servent', :s_name, :s_aliases, :s_port, :s_proto)

        def initialize(data)
          @p = Rubinius::FFI::MemoryPointer.new data.bytesize

          @p.write_string(data, data.bytesize)

          super(@p)
        end

        def to_s
          @p.read_string(size)
        end
      end
    end
  end
end
