require 'socket'

describe 'Addrinfo#ip_address' do
  describe 'using a String as the socket address' do
    it 'returns the IP as a String' do
      sockaddr = Socket.sockaddr_in(80, '127.0.0.1')
      addr     = Addrinfo.new(sockaddr)

      addr.ip_address.should == '127.0.0.1'
    end
  end

  describe 'using an Array as the socket address' do
    it 'returns the IP as a String' do
      sockaddr = ['AF_INET', 80, 'localhost', '127.0.0.1']
      addr     = Addrinfo.new(sockaddr)

      addr.ip_address.should == '127.0.0.1'
    end
  end
end
