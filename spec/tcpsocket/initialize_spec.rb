require 'socket'

describe 'TCPSocket#initialize' do
  describe 'when no server is listening on the given address' do
    it 'raises Errno::ECONNREFUSED' do
      proc { TCPSocket.new('127.0.0.1', 0) }
        .should raise_error(Errno::ECONNREFUSED)
    end
  end

  describe 'when a server is listening on the given address' do
    before do
      @server = TCPServer.new('127.0.0.1', 0)
      @port   = @server.connect_address.ip_port
    end

    after do
      @server.close
    end

    it 'returns a TCPSocket when using a Fixnum as the port' do
      TCPSocket.new('127.0.0.1', @port).should be_an_instance_of(TCPSocket)
    end

    it 'returns a TCPSocket when using a String as the port' do
      TCPSocket.new('127.0.0.1', @port.to_s).should be_an_instance_of(TCPSocket)
    end

    it 'raises SocketError when the port number is a non numeric String' do
      proc { TCPSocket.new('127.0.0.1', 'cats') }.should raise_error(SocketError)
    end

    it 'connects to the right address' do
      socket = TCPSocket.new('127.0.0.1', @port)

      socket.remote_address.ip_address.should == @server.local_address.ip_address
      socket.remote_address.ip_port.should    == @server.local_address.ip_port
    end
  end
end
