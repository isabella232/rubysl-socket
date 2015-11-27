module RubySL
  module Socket
    module ListenAndAccept
      include IO::Socketable

      def listen(backlog)
        backlog = Rubinius::Type.coerce_to(backlog, Fixnum, :to_int)

        err = RubySL::Socket::Foreign.listen(descriptor, backlog)

        Errno.handle('listen(2)') if err < 0

        0
      end

      def accept
        return if closed?

        fd = super

        socket = self.class.superclass.allocate
        IO.setup socket, fd, nil, true
        socket.binmode
        socket
      end

      #
      # Set nonblocking and accept.
      #
      def accept_nonblock
        return if closed?

        fcntl(::Fcntl::F_SETFL, ::Fcntl::O_NONBLOCK)

        fd = nil
        sockaddr = nil

        Rubinius::FFI::MemoryPointer.new 1024 do |sockaddr_p| # HACK from MRI
          Rubinius::FFI::MemoryPointer.new :int do |size_p|
            fd = RubySL::Socket::Foreign.accept descriptor, sockaddr_p, size_p
          end
        end

        Errno.handle 'accept(2)' if fd < 0

        # TCPServer -> TCPSocket etc. *sigh*
        socket = self.class.superclass.allocate
        IO.setup socket, fd, nil, true
        socket
      end
    end
  end
end
