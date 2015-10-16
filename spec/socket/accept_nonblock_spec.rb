require File.expand_path('../../fixtures/classes', __FILE__)

require 'socket'

describe "Socket#accept_nonblock" do
  before :each do
    @hostname = "127.0.0.1"
    @addr = Socket.sockaddr_in(0, @hostname)
    @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
    @socket.bind(@addr)
    @socket.listen(1)
  end

  after :each do
    @socket.close
  end

  it 'raises IO::EAGAINWaitReadable if the connection is not accepted yet' do
    lambda { @socket.accept_nonblock }.should raise_error(IO::EAGAINWaitReadable)
  end
end
