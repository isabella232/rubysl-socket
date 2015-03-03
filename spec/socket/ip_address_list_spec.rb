require 'socket'

describe 'Socket.ip_address_list' do
  it 'returns an Array of Addrinfo instances' do
    list = Socket.ip_address_list

    list.should be_an_instance_of(Array)
    list[0].should be_an_instance_of(Addrinfo)
  end

  it 'sets the IP address of the Addrinfo instances' do
    list = Socket.ip_address_list

    list[0].ip_address.should be_an_instance_of(String)
  end
end
