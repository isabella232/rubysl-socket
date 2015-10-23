require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)

describe 'Socket#connect' do
  before do
    @sock = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, Socket::IPPROTO_TCP)

    @sockaddr = Socket.pack_sockaddr_in(SocketSpecs.port, '127.0.0.1')
  end

  after do
    @sock.close
  end

  describe 'using a valid address' do
    before :all do
      SocketSpecs::SpecTCPServer.start
    end

    after :all do
      SocketSpecs::SpecTCPServer.shutdown
    end

    it 'returns 0' do
      @sock.connect(@sockaddr).should == 0
    end
  end

  describe 'using an invalid address' do
    it 'raises Errno::ECONNREFUSED' do
      proc { @sock.connect(@sockaddr) }.should raise_error(Errno::ECONNREFUSED)
    end
  end
end
