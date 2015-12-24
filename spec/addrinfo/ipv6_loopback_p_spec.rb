require 'socket'

describe 'Addrinfo#ipv6_loopback?' do
  it 'returns true for a loopback address' do
    Addrinfo.ip('::1').ipv6_loopback?.should == true
  end

  it 'returns false for a regular IPv6 address' do
    Addrinfo.ip('::2').ipv6_loopback?.should == false
  end
end
