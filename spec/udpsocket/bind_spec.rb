require 'socket'

describe 'UDPSocket#bind' do
  before do
    @socket = UDPSocket.new
  end

  after do
    @socket.close
  end

  it 'binds to an address and port' do
    @socket.bind('127.0.0.1', 0).should == 0

    @socket.local_address.ip_address.should == '127.0.0.1'
    @socket.local_address.ip_port.should > 0
  end

  it 'binds to all addresses when the hostname is empty' do
    @socket.bind('', 0).should == 0

    @socket.local_address.ip_address.should == '0.0.0.0'
  end
end
