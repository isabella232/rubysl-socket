module RubySL
  module Socket
    def self.bsd_support?
      Rubinius.bsd? || Rubinius.darwin?
    end

    def self.unix_socket_support?
      ::Socket::Constants.const_defined?(:AF_UNIX)
    end

    def self.aliases_for_hostname(hostname)
      pointer = Foreign.gethostbyname(hostname)

      Foreign::Hostent.new(pointer).aliases
    end

    def self.sockaddr_class_for_socket(socket)
      case Helpers.address_info(:getsockname, socket)[0]
      when 'AF_INET6'
        RubySL::Socket::Foreign::SockaddrIn6
      when 'AF_UNIX'
        RubySL::Socket::Foreign::SockaddrUn
      else
        RubySL::Socket::Foreign::SockaddrIn
      end
    end

    def self.sockaddr_class_for_string(sockaddr)
      case sockaddr.bytesize
      when 16
        RubySL::Socket::Foreign::SockaddrIn
      when 28
        RubySL::Socket::Foreign::SockaddrIn6
      when 110
        RubySL::Socket::Foreign::SockaddrUn
      else
        raise ArgumentError, 'invalid destination address'
      end
    end

    def self.accept(source, new_class)
      raise IOError, 'socket has been closed' if source.closed?

      sockaddr = sockaddr_class_for_socket(source).new

      begin
        fd = RubySL::Socket::Foreign.memory_pointer(:int) do |size_p|
          size_p.write_int(sockaddr.size)

          RubySL::Socket::Foreign
            .accept(source.descriptor, sockaddr.pointer, size_p)
        end

        Error.read_error('accept(2)', source) if fd < 0

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

      Error.read_error('listen(2)', source) if err < 0

      0
    end

    def self.family_for_sockaddr_in(sockaddr)
      sockaddr.bytesize == 28 ? ::Socket::AF_INET6 : ::Socket::AF_INET
    end

    def self.constant_pairs
      Rubinius::FFI.config_hash('socket').reject { |name, value| value.empty? }
    end
  end
end
