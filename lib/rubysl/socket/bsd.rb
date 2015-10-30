# This file is only available on BSD/Darwin systems.

module RubySL
  module Socket
    module BSD
      extend Rubinius::FFI::Library

      attach_function :_getpeereid,
        :getpeereid, [:int, :pointer, :pointer], :int

      def self.getpeereid(descriptor)
        euid = Rubinius::FFI::MemoryPointer.new(:int)
        egid = Rubinius::FFI::MemoryPointer.new(:int)

        begin
          res = _getpeereid(descriptor, euid, egid)

          if res == 0
            [euid.read_int, egid.read_int]
          else
            Errno.handle('getpeereid(3)')
          end
        ensure
          euid.free
          egid.free
        end
      end
    end
  end
end
