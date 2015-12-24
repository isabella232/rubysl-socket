require 'socket'

describe 'Addrinfo#ipv6_linklocal?' do
  it 'returns true for a link-local address' do
    Addrinfo.ip('fe80::').ipv6_linklocal?.should == true
    Addrinfo.ip('fe80::1').ipv6_linklocal?.should == true
  end

  it 'returns false for a regular address' do
    Addrinfo.ip('::1').ipv6_linklocal?.should == false
  end
end
