module RubySL
  module Socket
    module ListenAndAccept
      def listen(backlog)
        backlog = Rubinius::Type.coerce_to(backlog, Fixnum, :to_int)

        err = RubySL::Socket::Foreign.listen(descriptor, backlog)

        Errno.handle('listen(2)') if err < 0

        0
      end

      def accept
        raise IOError, 'socket has been closed' if closed?

        sockaddr = RubySL::Socket::Foreign::Sockaddr.new

        begin
          fd = RubySL::Socket::Foreign.memory_pointer(:int) do |size_p|
            size_p.write_int(sockaddr.size)

            RubySL::Socket::Foreign.accept(descriptor, sockaddr.pointer, size_p)
          end

          Errno.handle('accept(2)') if fd < 0

          # Socket#accept should produce a Socket, TCPServer#accept should
          # produce a TCPSocket, etc.
          if self.class == ::Socket
            socket = ::Socket.allocate
          else
            socket = self.class.superclass.allocate
          end

          IO.setup(socket, fd, nil, true)
          socket.binmode

          socktype = getsockopt(:SOCKET, :TYPE).int
          addrinfo = Addrinfo.new(sockaddr.to_s, sockaddr.family, socktype)

          return socket, addrinfo
        ensure
          sockaddr.free
        end
      end

      def accept_nonblock
        fcntl(::Fcntl::F_SETFL, ::Fcntl::O_NONBLOCK)

        accept
      end
    end
  end
end
