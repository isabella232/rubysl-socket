require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)

describe 'Socket#recvfrom' do
  before do
    @server   = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    @client   = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    @sockaddr = Socket.pack_sockaddr_in(SocketSpecs.port, '127.0.0.1')

    @server.bind(@sockaddr)
    @server.listen(1)
  end

  after do
    @server.close
    @client.close
  end

  before do
    @output = nil
    @addr   = nil

    thread = Thread.new do
      client, _ = @server.accept

      @output, @addr = client.recvfrom(2)

      client.close
    end

    @client.connect(@sockaddr)
    @client.write('1234')

    thread.join
  end

  it 'returns the read bytes as a String' do
    @output.should == '12'
  end

  it 'returns an Addrinfo' do
    @addr.should be_an_instance_of(Addrinfo)
  end

  describe 'the returned Addrinfo' do
    it 'uses AF_UNSPEC as the address family' do
      @addr.afamily.should == Socket::AF_UNSPEC
    end

    it 'uses PF_UNSPEC as the protocol family' do
      @addr.pfamily.should == Socket::PF_UNSPEC
    end

    it 'uses SOCK_STREAM as the socket type' do
      @addr.socktype.should == Socket::SOCK_STREAM
    end

    it 'raises SocketError when calling #ip_address' do
      proc { @addr.ip_address }.should raise_error(SocketError)
    end

    it 'raises SocketError when calling #ip_port' do
      proc { @addr.ip_port }.should raise_error(SocketError)
    end
  end
end
