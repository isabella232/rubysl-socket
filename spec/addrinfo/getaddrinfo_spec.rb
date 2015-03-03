require 'socket'

describe 'Addrinfo.getaddrinfo' do
  it 'returns an Array of Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80)

    array.should be_an_instance_of(Array)
    array[0].should be_an_instance_of(Addrinfo)
  end

  it 'sets the IP address of the Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80)

    array[0].ip_address.should == '127.0.0.1'
  end

  it 'sets the port of the Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80)

    array[0].ip_port.should == 80
  end

  it 'sets the default address family of the Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80)

    array[0].afamily.should == Socket::AF_INET
  end

  it 'sets the default protocol family of the Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80)

    array[0].pfamily.should == Socket::PF_INET
  end

  it 'sets a custom protocol family of the Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80, Socket::PF_INET6)

    array[0].pfamily.should == Socket::PF_INET6
  end

  it 'sets a corresponding address family based on a custom protocol family' do
    array = Addrinfo.getaddrinfo('localhost', 80, Socket::PF_INET6)

    array[0].afamily.should == Socket::AF_INET6
  end

  it 'sets the default socket type of the Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80)

    array[0].socktype.should == Socket::SOCK_STREAM
  end

  it 'sets a custom socket type of the Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80, nil, Socket::SOCK_DGRAM)

    array[0].socktype.should == Socket::SOCK_DGRAM
  end

  it 'sets the default socket protocol of the Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80)

    array[0].protocol.should == Socket::IPPROTO_TCP
  end

  it 'sets a custom socket protocol of the Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80, nil, nil, Socket::IPPROTO_UDP)

    array[0].protocol.should == Socket::IPPROTO_UDP
  end

  it 'sets custom socket flags of the Addrinfo instances' do
    array = Addrinfo.getaddrinfo('localhost', 80, nil, nil, nil, Socket::AI_CANONNAME)

    array[0].canonname.should be_an_instance_of(String)
  end
end
