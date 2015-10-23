require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)

describe 'UNIXSocket#remote_address' do
  platform_is_not :windows do
    before :all do
      @path = SocketSpecs.socket_path

      rm_r @path

      @server = UNIXServer.new(@path)
    end

    after :all do
      @server.close

      rm_r @path
    end

    before do
      @sock = UNIXSocket.new(@path)
    end

    after do
      @sock.close
    end

    it 'returns an Addrinfo' do
      @sock.remote_address.should be_an_instance_of(Addrinfo)
    end

    describe 'the returned Addrinfo' do
      it 'uses AF_UNIX as the address family' do
        @sock.remote_address.afamily.should == Socket::AF_UNIX
      end

      it 'uses PF_UNIX as the protocol family' do
        @sock.remote_address.pfamily.should == Socket::PF_UNIX
      end

      it 'uses SOCK_STREAM as the socket type' do
        @sock.remote_address.socktype.should == Socket::SOCK_STREAM
      end

      it 'uses the correct socket path' do
        @sock.remote_address.unix_path.should == @path
      end

      it 'uses 0 as the protocol' do
        @sock.remote_address.protocol.should == 0
      end
    end
  end
end
