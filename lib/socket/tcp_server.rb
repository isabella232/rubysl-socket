class TCPServer < TCPSocket
  def initialize(host, port = nil)
    @no_reverse_lookup = self.class.do_not_reverse_lookup

    if Fixnum === host and port.nil? then
      port = host
      host = nil
    end

    if String === host and port.nil? then
      port = Integer(host)
      host = nil
    end

    port = StringValue port unless port.kind_of? Fixnum

    @host = host
    @port = port

    tcp_setup @host, @port, nil, nil, true
  end

  def listen(backlog)
    RubySL::Socket::Listen.listen(self, backlog)
  end

  def accept
    RubySL::Socket::Accept.accept(self, TCPSocket)
  end

  def accept_nonblock
    RubySL::Socket::Accept.accept_nonblock(self, TCPSocket)
  end
end
