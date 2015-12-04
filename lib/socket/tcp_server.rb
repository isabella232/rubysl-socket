class TCPServer < TCPSocket
  def initialize(host, port = nil)
    @no_reverse_lookup = self.class.do_not_reverse_lookup

    if host.is_a?(Fixnum) and port.nil?
      port = host
      host = nil
    end

    if host.is_a?(String) and port.nil?
      begin
        port = Integer(host)
      rescue ArgumentError
        raise SocketError, "invalid port number: #{host}"
      end

      host = nil
    end

    unless port.kind_of?(Fixnum)
      port = RubySL::Socket::Helpers.coerce_to_string(port)
    end

    @host = host
    @port = port

    tcp_setup(@host, @port, nil, nil, true)
  end

  def listen(backlog)
    RubySL::Socket::Listen.listen(self, backlog)
  end

  def accept
    socket, _ = RubySL::Socket::Accept.accept(self, TCPSocket)

    socket
  end

  def accept_nonblock
    socket, _ = RubySL::Socket::Accept.accept_nonblock(self, TCPSocket)

    socket
  end

  def sysaccept
    accept.fileno
  end
end
