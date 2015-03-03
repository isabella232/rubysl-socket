require 'socket'

describe 'Addrinfo#ip_port' do
  describe 'using a String as the socket address' do
    it 'returns the port as a Fixnum' do
      sockaddr = Socket.sockaddr_in(80, '127.0.0.1')
      addr     = Addrinfo.new(sockaddr)

      addr.ip_port.should == 80
    end
  end

  describe 'using an Array as the socket address' do
    it 'returns the port as a Fixnum' do
      sockaddr = ['AF_INET', 80, 'localhost', '127.0.0.1']
      addr     = Addrinfo.new(sockaddr)

      addr.ip_port.should == 80
    end
  end
end
