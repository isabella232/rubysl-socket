class UDPSocket < IPSocket
  def initialize(family = Socket::AF_INET)
    @no_reverse_lookup = self.class.do_not_reverse_lookup
    @family            = RubySL::Socket::Helpers.address_family(family)

    descriptor = RubySL::Socket::Foreign
      .socket(@family, Socket::SOCK_DGRAM, Socket::IPPROTO_UDP)

    Errno.handle('socket(2)') if descriptor < 0

    IO.setup(self, descriptor, nil, true)
  end

  def bind(host, port)
    addr   = Socket.sockaddr_in(port.to_i, host)
    status = RubySL::Socket::Foreign.bind(descriptor, addr)

    Errno.handle('bind(2)') if status < 0

    0
  end

  def connect(host, port)
    sockaddr = Socket.sockaddr_in(port.to_i, host)
    status   = RubySL::Socket::Foreign.connect(descriptor, sockaddr)

    Errno.handle('connect(2)') if status < 0

    0
  end

  def send(message, flags, *to)
    connect *to unless to.empty?

    bytes = message.bytesize
    bytes_sent = 0

    Rubinius::FFI::MemoryPointer.new :char, bytes + 1 do |buffer|
      buffer.write_string message, bytes
      bytes_sent = RubySL::Socket::Foreign.send(descriptor, buffer, bytes, flags)
      Errno.handle 'send(2)' if bytes_sent < 0
    end

    bytes_sent
  end

  def recvfrom_nonblock(maxlen, flags = 0)
    fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)

    flags = 0 if flags.nil?

    flags |= Socket::MSG_DONTWAIT

    recvfrom(maxlen, flags)
  end

  def inspect
    "#<#{self.class}:0x#{object_id.to_s(16)} #{@host}:#{@port}>"
  end

  def local_address
    address  = addr
    sockaddr = Socket.pack_sockaddr_in(address[1], address[3])

    Addrinfo.new(sockaddr, address[0], :DGRAM)
  end

  def remote_address
    address  = peeraddr
    sockaddr = Socket.pack_sockaddr_in(address[1], address[3])

    Addrinfo.new(sockaddr, address[0], :DGRAM)
  end
end
