describe :socket_accept, :shared => true do
  before do
    addr    = Socket.sockaddr_in(@server.local_address.ip_port, '127.0.0.1')
    @client = Socket.new(:INET, :STREAM, 0)

    @client.connect(addr)
  end

  after do
    @client.close
  end

  it 'returns an Array containing a Socket and an Addrinfo' do
    socket, addrinfo = @server.__send__(@method)

    socket.should be_an_instance_of(Socket)
    addrinfo.should be_an_instance_of(Addrinfo)
  end

  describe 'the returned Addrinfo' do
    before do
      _, @addr = @server.__send__(@method)
    end

    it 'uses AF_INET as the address family' do
      @addr.afamily.should == Socket::AF_INET
    end

    it 'uses PF_INET as the protocol family' do
      @addr.pfamily.should == Socket::PF_INET
    end

    it 'uses SOCK_STREAM as the socket type' do
      @addr.socktype.should == Socket::SOCK_STREAM
    end

    it 'uses 0 as the protocol' do
      @addr.protocol.should == 0
    end

    it 'uses the same IP address as the client Socket' do
      @addr.ip_address.should == @client.local_address.ip_address
    end

    it 'uses the same port as the client Socket' do
      @addr.ip_port.should == @client.local_address.ip_port
    end
  end
end
