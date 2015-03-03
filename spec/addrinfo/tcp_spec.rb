require 'socket'

describe 'Addrinfo.tcp' do
  describe 'using an IPv4 address' do
    it 'returns an Addrinfo instance' do
      Addrinfo.tcp('127.0.0.1', 80).should be_an_instance_of(Addrinfo)
    end

    it 'sets the IP address' do
      Addrinfo.tcp('127.0.0.1', 80).ip_address.should == '127.0.0.1'
    end

    it 'sets the port' do
      Addrinfo.tcp('127.0.0.1', 80).ip_port.should == 80
    end

    it 'sets the address family' do
      Addrinfo.tcp('127.0.0.1', 80).afamily.should == Socket::AF_INET
    end

    it 'sets the protocol family' do
      Addrinfo.tcp('127.0.0.1', 80).pfamily.should == Socket::PF_INET
    end

    it 'sets the socket type' do
      Addrinfo.tcp('127.0.0.1', 80).socktype.should == Socket::SOCK_STREAM
    end

    it 'sets the socket protocol' do
      Addrinfo.tcp('127.0.0.1', 80).protocol.should == Socket::IPPROTO_TCP
    end
  end

  describe 'using an IPv6 address' do
    it 'returns an Addrinfo instance' do
      Addrinfo.tcp('::1', 80).should be_an_instance_of(Addrinfo)
    end

    it 'sets the IP address' do
      Addrinfo.tcp('::1', 80).ip_address.should == '::1'
    end

    it 'sets the port' do
      Addrinfo.tcp('::1', 80).ip_port.should == 80
    end

    it 'sets the address family' do
      Addrinfo.tcp('::1', 80).afamily.should == Socket::AF_INET6
    end

    it 'sets the protocol family' do
      Addrinfo.tcp('::1', 80).pfamily.should == Socket::PF_INET6
    end

    it 'sets the socket type' do
      Addrinfo.tcp('::1', 80).socktype.should == Socket::SOCK_STREAM
    end

    it 'sets the socket protocol' do
      Addrinfo.tcp('::1', 80).protocol.should == Socket::IPPROTO_TCP
    end
  end
end
