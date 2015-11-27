require 'socket'

describe 'Socket#connect' do
  before do
    @server = Socket.new(:INET, :STREAM)
    @client = Socket.new(:INET, :STREAM)

    @server.bind(Socket.sockaddr_in(0, '127.0.0.1'))
  end

  after do
    @client.close
    @server.close
  end

  it 'returns 0 when connected successfully using a String' do
    @server.listen(1)

    @client.connect(@server.getsockname).should == 0
  end

  it 'returns 0 when connected successfully using an Addrinfo' do
    @server.listen(1)

    @client.connect(@server.connect_address).should == 0
  end

  it 'raises Errno::EISCONN when already connected' do
    @server.listen(1)

    @client.connect(@server.getsockname).should == 0

    proc { @client.connect(@server.getsockname) }
      .should raise_error(Errno::EISCONN)
  end

  it 'raises Errno::ECONNREFUSED when the connection failed' do
    proc { @client.connect(@server.getsockname) }
      .should raise_error(Errno::ECONNREFUSED)
  end
end
