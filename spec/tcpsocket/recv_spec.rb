require 'socket'

describe 'TCPSocket#recv' do
  before do
    @server = TCPServer.new('127.0.0.1', 0)
    @client = TCPSocket.new('127.0.0.1', @server.connect_address.ip_port)
  end

  after do
    @client.close
    @server.close
  end

  it 'returns the message data' do
    @client.write('hello')

    socket = @server.accept

    begin
      socket.recv(5).should == 'hello'
    ensure
      socket.close
    end
  end
end
