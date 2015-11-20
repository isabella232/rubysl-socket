module RubySL
  module Socket
    module Foreign
      class Msghdr < Rubinius::FFI::Struct
        config('rbx.platform.msghdr', :msg_name, :msg_namelen, :msg_iov,
               :msg_iovlen, :msg_control, :msg_controllen, :msg_flags)

        def self.with_buffers(ctl_buffer, address, io_vec)
          header = new

          header[:msg_control]    = ctl_buffer
          header[:msg_controllen] = ctl_buffer.total
          header[:msg_name]       = address.pointer
          header[:msg_namelen]    = address.pointer.total
          header[:msg_iov]        = io_vec.pointer
          header[:msg_iovlen]     = 1

          header
        end

        def flags
          self[:msg_flags]
        end

        def message_truncated?
          flags & ::Socket::MSG_TRUNC > 0
        end

        def control_truncated?
          flags & ::Socket::MSG_CTRUNC > 0
        end
      end
    end
  end
end
