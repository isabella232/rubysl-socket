module RubySL
  module Socket
    module Accept
      def self.accept(source, new_class)
        raise IOError, 'socket has been closed' if source.closed?

        sockaddr = RubySL::Socket::Foreign::Sockaddr.new

        begin
          fd = RubySL::Socket::Foreign.memory_pointer(:int) do |size_p|
            size_p.write_int(sockaddr.size)

            RubySL::Socket::Foreign
              .accept(source.descriptor, sockaddr.pointer, size_p)
          end

          Errno.handle('accept(2)') if fd < 0

          socket = new_class.allocate

          IO.setup(socket, fd, nil, true)
          socket.binmode

          socktype = source.getsockopt(:SOCKET, :TYPE).int
          addrinfo = Addrinfo.new(sockaddr.to_s, sockaddr.family, socktype)

          return socket, addrinfo
        ensure
          sockaddr.free
        end
      end

      def self.accept_nonblock(source, new_class)
        source.fcntl(::Fcntl::F_SETFL, ::Fcntl::O_NONBLOCK)

        accept(source, new_class)
      end
    end
  end
end
