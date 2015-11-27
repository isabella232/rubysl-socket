require 'socket'

describe 'Socket#ipv6only!' do
  it 'enables IPv6 only mode' do
    socket = Socket.new(:INET6, :DGRAM)

    socket.ipv6only!

    socket.getsockopt(:IPV6, :V6ONLY).bool.should == true
  end
end
