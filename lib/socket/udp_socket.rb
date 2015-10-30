class UDPSocket < IPSocket
  def initialize(family = Socket::AF_INET)
    @no_reverse_lookup = self.class.do_not_reverse_lookup
    @family = family
    status = RubySL::Socket::Foreign.socket @family,
                                    Socket::SOCK_DGRAM,
                                    Socket::IPPROTO_UDP
    Errno.handle 'socket(2)' if status < 0

    IO.setup self, status, nil, true
  end

  def bind(host, port)
    @host = host.to_s if host
    @port = port.to_s if port

    addrinfos = RubySL::Socket::Foreign.getaddrinfo(@host,
                                           @port,
                                           @family,
                                           Socket::SOCK_DGRAM, 0,
                                           Socket::AI_PASSIVE)

    status = -1

    addrinfos.each do |addrinfo|
      flags, family, socket_type, protocol, sockaddr, canonname = addrinfo

      status = RubySL::Socket::Foreign.bind descriptor, sockaddr

      break if status >= 0
    end

    if status < 0
      Errno.handle 'bind(2)'
    end

    status
  end

  def connect(host, port)
    sockaddr = RubySL::Socket::Foreign.pack_sockaddr_in host, port, @family, Socket::SOCK_DGRAM, 0

    syscall = 'connect(2)'
    status = RubySL::Socket::Foreign.connect descriptor, sockaddr

    if status < 0
      Errno.handle syscall
    end

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