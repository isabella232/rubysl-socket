require 'socket'

describe 'UDPSocket#connect' do
  before do
    @socket = UDPSocket.new
  end

  after do
    @socket.close
  end

  it 'connects to an address even when it is not used' do
    @socket.connect('127.0.0.1', 0).should == 0
  end

  it 'can send data after connecting' do
    receiver = UDPSocket.new

    receiver.bind('127.0.0.1', 0)

    addr = receiver.connect_address

    @socket.connect(addr.ip_address, addr.ip_port)
    @socket.write('hello')

    begin
      receiver.recv(6).should == 'hello'
    ensure
      receiver.close
    end
  end
end
