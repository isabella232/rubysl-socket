require 'socket'

describe 'TCPServer#accept' do
  before do
    @server = TCPServer.new('127.0.0.1', 0)
  end

  after do
    @server.close
  end

  describe 'without a connected client' do
    it 'raises IO::EAGAINWaitReadable' do
      proc { @server.accept_nonblock }.should raise_error(IO::EAGAINWaitReadable)
    end
  end

  describe 'with a connected client' do
    before do
      @client = TCPSocket.new('127.0.0.1', @server.connect_address.ip_port)
    end

    after do
      @client.close
    end

    it 'returns a TCPSocket' do
      @server.accept_nonblock.should be_an_instance_of(TCPSocket)
    end
  end
end
