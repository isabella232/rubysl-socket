require 'socket'

describe 'Addrinfo.ip' do
  describe 'using an IPv4 address' do
    it 'returns an Addrinfo instance' do
      Addrinfo.ip('127.0.0.1').should be_an_instance_of(Addrinfo)
    end

    it 'sets the IP address' do
      Addrinfo.ip('127.0.0.1').ip_address.should == '127.0.0.1'
    end

    it 'sets the port to 0' do
      Addrinfo.ip('127.0.0.1').ip_port.should == 0
    end

    it 'sets the address family' do
      Addrinfo.ip('127.0.0.1').afamily.should == Socket::AF_INET
    end

    it 'sets the protocol family' do
      Addrinfo.ip('127.0.0.1').pfamily.should == Socket::PF_INET
    end

    it 'sets the socket type to 0' do
      Addrinfo.ip('127.0.0.1').socktype.should == 0
    end
  end

  describe 'using an IPv6 address' do
    it 'returns an Addrinfo instance' do
      Addrinfo.ip('::1').should be_an_instance_of(Addrinfo)
    end

    it 'sets the IP address' do
      Addrinfo.ip('::1').ip_address.should == '::1'
    end

    it 'sets the port to 0' do
      Addrinfo.ip('::1').ip_port.should == 0
    end

    it 'sets the address family' do
      Addrinfo.ip('::1').afamily.should == Socket::AF_INET6
    end

    it 'sets the protocol family' do
      Addrinfo.ip('::1').pfamily.should == Socket::PF_INET6
    end

    it 'sets the socket type to 0' do
      Addrinfo.ip('::1').socktype.should == 0
    end
  end
end

describe "Addrinfo#ip?" do
  it "needs to be reviewed for spec completeness"
end
