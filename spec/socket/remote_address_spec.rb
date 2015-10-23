require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)

describe 'Socket#remote_address' do
  before :all do
    SocketSpecs::SpecTCPServer.start
  end

  after :all do
    SocketSpecs::SpecTCPServer.cleanup
  end

  before do
    server = SocketSpecs::SpecTCPServer.get

    @sock = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, Socket::IPPROTO_TCP)
    @host = server.hostname
    @port = server.port

    @sock.connect(Socket.pack_sockaddr_in(@port, @host))
  end

  after do
    @sock.close
  end

  it 'returns an Addrinfo' do
    @sock.remote_address.should be_an_instance_of(Addrinfo)
  end

  describe 'the returned Addrinfo' do
    it 'uses AF_INET as the address family' do
      @sock.remote_address.afamily.should == Socket::AF_INET
    end

    it 'uses PF_INET as the protocol family' do
      @sock.remote_address.pfamily.should == Socket::PF_INET
    end

    it 'uses SOCK_STREAM as the socket type' do
      @sock.remote_address.socktype.should == Socket::SOCK_STREAM
    end

    it 'uses the correct IP address' do
      @sock.remote_address.ip_address.should == @host
    end

    it 'uses the correct port' do
      @sock.remote_address.ip_port.should == @port
    end

    it 'uses 0 as the protocol' do
      @sock.remote_address.protocol.should == 0
    end
  end
end
