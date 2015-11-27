require 'socket'

describe 'IPSocket#recvfrom' do
  before do
    @server = UDPSocket.new
    @client = UDPSocket.new
    @ip     = '127.0.0.1'

    @server.bind(@ip, 0)
    @client.connect(@ip, @server.connect_address.ip_port)

    @hostname = Socket.getaddrinfo(@ip, nil)[0][2]
  end

  after do
    @client.close
    @server.close
  end

  it 'returns an Array containing up to N bytes and address information' do
    @client.write('hello')

    port = @client.local_address.ip_port
    ret  = @server.recvfrom(2)

    ret.should == ['he', ['AF_INET', port, @hostname, @ip]]
  end

  it 'allows specifying of flags when receiving data' do
    @client.write('hello')

    @server.recvfrom(2, Socket::MSG_PEEK)[0].should == 'he'

    @server.recvfrom(2)[0].should == 'he'
  end
end
