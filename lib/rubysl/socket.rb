module RubySL
  module Socket
    def self.bsd_support?
      Rubinius.bsd? || Rubinius.darwin?
    end

    def self.aliases_for_hostname(hostname)
      pointer  = Foreign.gethostbyname(hostname)
      struct   = Foreign::Hostent.new(pointer)
      pointers = struct[:h_aliases].get_array_of_pointer(0, struct[:h_length])

      pointers.map { |p| p.read_string }
    end

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

    def self.listen(source, backlog)
      backlog = Rubinius::Type.coerce_to(backlog, Fixnum, :to_int)
      err     = Foreign.listen(source.descriptor, backlog)

      Errno.handle('listen(2)') if err < 0

      0
    end
  end
end
