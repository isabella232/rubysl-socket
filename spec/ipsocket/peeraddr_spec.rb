require 'socket'

describe 'IPSocket#peeraddr' do
  before do
    @ip     = '127.0.0.1'
    @server = TCPServer.new(@ip, 0)
    @port   = @server.connect_address.ip_port
    @client = TCPSocket.new(@ip, @port)
  end

  after do
    @client.close
    @server.close
  end

  describe 'without reverse lookups' do
    before do
      @hostname = Socket.getaddrinfo(@ip, nil)[0][2]
    end

    it 'returns an Array containing address information' do
      @client.peeraddr.should == ['AF_INET', @port, @hostname, @ip]
    end
  end

  describe 'with reverse lookups' do
    before do
      @hostname = Socket.getaddrinfo(@ip, nil, nil, 0, 0, 0, true)[0][2]
    end

    describe 'using true as the argument' do
      it 'returns an Array containing address information' do
        @client.peeraddr(true).should == ['AF_INET', @port, @hostname, @ip]
      end
    end

    describe 'using :hostname as the argument' do
      it 'returns an Array containing address information' do
        @client.peeraddr(:hostname).should == ['AF_INET', @port, @hostname, @ip]
      end
    end

    describe 'using :cats as the argument' do
      it 'raises ArgumentError' do
        proc { @client.peeraddr(:cats) }.should raise_error(ArgumentError)
      end
    end
  end

  describe 'with do_not_reverse_lookup disabled on socket level' do
    before do
      @client.do_not_reverse_lookup = false

      @hostname = Socket.getaddrinfo(@ip, nil, nil, 0, 0, 0, true)[0][2]
      @port     = @client.local_address.ip_port
    end

    after do
      @client.do_not_reverse_lookup = true
    end

    it 'returns an Array containing address information' do
      @client.addr.should == ['AF_INET', @port, @hostname, @ip]
    end
  end
end
