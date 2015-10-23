require File.expand_path('../../fixtures/classes', __FILE__)
require 'socket'

describe 'TCPSocket#local_address' do
  before :all do
    SocketSpecs::SpecTCPServer.start
  end

  after :all do
    SocketSpecs::SpecTCPServer.cleanup
  end

  describe 'using an explicit hostname' do
    before do
      server = SocketSpecs::SpecTCPServer.get

      @host = server.hostname
      @port = server.port
      @sock = TCPSocket.new(@host, @port)
    end

    after do
      @sock.close
    end

    it 'returns an Addrinfo' do
      @sock.local_address.should be_an_instance_of(Addrinfo)
    end

    describe 'the returned Addrinfo' do
      it 'uses AF_INET as the address family' do
        @sock.local_address.afamily.should == Socket::AF_INET
      end

      it 'uses PF_INET as the protocol family' do
        @sock.local_address.pfamily.should == Socket::PF_INET
      end

      it 'uses SOCK_STREAM as the socket type' do
        @sock.local_address.socktype.should == Socket::SOCK_STREAM
      end

      it 'uses the correct IP address' do
        @sock.local_address.ip_address.should == @host
      end

      it 'uses a randomly assigned local port' do
        @sock.local_address.ip_port.should > 0
        @sock.local_address.ip_port.should_not == @port
      end

      it 'uses 0 as the protocol' do
        @sock.local_address.protocol.should == 0
      end
    end
  end

  describe 'using an implicit hostname' do
    before do
      server = SocketSpecs::SpecTCPServer.get

      @host = server.hostname
      @port = server.port
      @sock = TCPSocket.new(nil, @port)
    end

    after do
      @sock.close
    end

    describe 'the returned Addrinfo' do
      it 'uses the correct IP address' do
        @sock.local_address.ip_address.should == @host
      end
    end
  end
end
