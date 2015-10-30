class TCPServer < TCPSocket
  include RubySL::Socket::ListenAndAccept

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
end
