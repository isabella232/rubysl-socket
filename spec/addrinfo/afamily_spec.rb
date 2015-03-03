require 'socket'

describe 'Addrinfo#afamily' do
  it 'returns AF_INET as the default address family' do
    sockaddr = Socket.pack_sockaddr_in(80, 'localhost')

    Addrinfo.new(sockaddr).afamily.should == Socket::AF_INET
  end

  it 'returns AF_UNIX as the address family for Unix sockets' do
    sockaddr = Socket.pack_sockaddr_un('socket')

    Addrinfo.new(sockaddr).afamily.should == Socket::AF_UNIX
  end
end
