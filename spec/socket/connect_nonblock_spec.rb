require 'socket'

describe 'Socket#connect_nonblock' do
  describe 'using a DGRAM socket' do
    before do
      @server   = Socket.new(:INET, :DGRAM)
      @client   = Socket.new(:INET, :DGRAM)
      @sockaddr = Socket.sockaddr_in(0, '127.0.0.1')

      @server.bind(@sockaddr)
    end

    after do
      @client.close
      @server.close
    end

    it 'returns 0 when successfully connected using a String' do
      @client.connect_nonblock(@server.getsockname).should == 0
    end

    it 'returns 0 when successfully connected using an Addrinfo' do
      @client.connect_nonblock(@server.connect_address).should == 0
    end

    it 'raises TypeError when passed a Fixnum' do
      proc { @client.connect_nonblock(666) }.should raise_error(TypeError)
    end
  end

  describe 'using a STREAM socket' do
    before do
      @server   = Socket.new(:INET, :STREAM)
      @client   = Socket.new(:INET, :STREAM)
      @sockaddr = Socket.sockaddr_in(0, '127.0.0.1')
    end

    after do
      @client.close
      @server.close
    end

    it 'raises IO:EINPROGRESSWaitWritable when the connection would block' do
      @server.bind(@sockaddr)

      proc { @client.connect_nonblock(@server.getsockname) }
        .should raise_error(IO::EINPROGRESSWaitWritable)
    end
  end
end
