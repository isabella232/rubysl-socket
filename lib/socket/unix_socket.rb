class UNIXSocket < BasicSocket
  include IO::TransferIO

  def self.socketpair(type = Socket::SOCK_STREAM, protocol = 0)
    Socket.socketpair(Socket::AF_UNIX, type, protocol, self)
  end

  class << self
    alias_method :pair, :socketpair
  end

  def initialize(path)
    @no_reverse_lookup = self.class.do_not_reverse_lookup
    @path              = '' # empty for client sockets

    fd = RubySL::Socket::Foreign.socket(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)

    Errno.handle('socket(2)') if fd < 0

    IO.setup(self, fd, 'r+', true)

    sockaddr = Socket.sockaddr_un(path)
    status   = RubySL::Socket::Foreign.connect(descriptor, sockaddr)

    Errno.handle('connect(2)') if status < 0
  end

  def recvfrom(bytes_read, flags = 0)
    socket_recv(bytes_read, flags, 2)
  end

  def path
    @path ||= RubySL::Socket::Foreign.getsockname(descriptor).unpack('SZ*')[1]
  end

  def addr
    ['AF_UNIX', path]
  end

  def peeraddr
    path = RubySL::Socket::Foreign.getpeername(descriptor).unpack('SZ*')[1]

    ['AF_UNIX', path]
  end

  def recv_io(klass = IO, mode = nil)
    begin
      fd = recv_fd
    rescue PrimitiveFailure
      raise SocketError, "file descriptor was not passed"
    end

    return fd unless klass

    if klass.is_a?(BasicSocket)
      klass.for_fd(fd)
    else
      klass.for_fd(fd, mode)
    end
  end

  def local_address
    address = addr

    Addrinfo.new(Socket.pack_sockaddr_un(address[1]), :UNIX, :STREAM)
  end

  def remote_address
    address = peeraddr

    Addrinfo.new(Socket.pack_sockaddr_un(address[1]), :UNIX, :STREAM)
  end
end
