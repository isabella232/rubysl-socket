class UNIXSocket < BasicSocket
  include IO::TransferIO

  class << self
    def socketpair(type=Socket::SOCK_STREAM, protocol=0)
      Socket.socketpair(Socket::PF_UNIX, type, protocol, self)
    end

    alias_method :pair, :socketpair
  end

  # Coding to the lowest standard here.
  def recvfrom(bytes_read, flags = 0)
    # FIXME 2 is hardcoded knowledge from io.cpp
    socket_recv(bytes_read, flags, 2)
  end

  def initialize(path)
    @no_reverse_lookup = self.class.do_not_reverse_lookup
    @path = path
    unix_setup
    @path = ""  # Client
  end

  def path
    unless @path
      sockaddr = RubySL::Socket::Foreign.getsockname descriptor
      _, @path = sockaddr.unpack('SZ*')
    end

    return @path
  end

  def from_descriptor(fixnum)
    super
    @path = nil
  end

  def addr
    sockaddr = RubySL::Socket::Foreign.getsockname descriptor
    _, sock_path = sockaddr.unpack('SZ*')
    ["AF_UNIX", sock_path]
  end

  def peeraddr
    sockaddr = RubySL::Socket::Foreign.getpeername descriptor
    _, sock_path = sockaddr.unpack('SZ*')
    ["AF_UNIX", sock_path]
  end

  def recv_io(klass=IO, mode=nil)
    begin
      fd = recv_fd
    rescue PrimitiveFailure
      raise SocketError, "file descriptor was not passed"
    end

    return fd unless klass

    if klass < BasicSocket
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

  private

  def unix_setup(server = false)
    status = nil
    phase = 'socket(2)'
    sock = RubySL::Socket::Foreign
      .socket(Socket::Constants::AF_UNIX, Socket::Constants::SOCK_STREAM, 0)

    Errno.handle phase if sock < 0

    IO.setup self, sock, 'r+', true

    sockaddr = Socket.pack_sockaddr_un(@path)

    if server then
      phase = 'bind(2)'
      status = RubySL::Socket::Foreign.bind descriptor, sockaddr
    else
      phase = 'connect(2)'
      status = RubySL::Socket::Foreign.connect descriptor, sockaddr
    end

    if status < 0 then
      close
      Errno.handle phase
    end

    if server then
      phase = 'listen(2)'
      status = RubySL::Socket::Foreign.listen descriptor, 5
      if status < 0
        close
        Errno.handle phase
      end
    end

    return sock
  end
end
