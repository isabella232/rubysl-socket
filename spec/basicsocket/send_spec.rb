require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)

describe 'BasicSocket#send' do
  describe 'using a disconnected socket' do
    before do
      @client = Socket.new(:INET, :DGRAM)
      @server = Socket.new(:INET, :DGRAM)

      @server.bind(Socket.sockaddr_in(0, '127.0.0.1'))
    end

    after do
      @client.close
      @server.close
    end

    describe 'without a destination address' do
      it 'raises Errno::EDESTADDRREQ' do
        proc { @client.send('hello', 0) }.should raise_error(Errno::EDESTADDRREQ)
      end
    end

    describe 'with a destination address as a String' do
      it 'returns the amount of sent bytes' do
        @client.send('hello', 0, @server.getsockname).should == 5
      end

      it 'does not persist the connection after writing to the socket' do
        @client.send('hello', 0, @server.getsockname)

        proc { @client.send('hello', 0) }.should raise_error(Errno::EDESTADDRREQ)
      end
    end

    describe 'with a destination address as an Addrinfo' do
      it 'returns the amount of sent bytes' do
        @client.send('hello', 0, @server.connect_address).should == 5
      end
    end
  end

  describe 'using a connected UDP socket' do
    before do
      @client = Socket.new(:INET, :DGRAM)
      @server = Socket.new(:INET, :DGRAM)

      @server.bind(Socket.sockaddr_in(0, '127.0.0.1'))
      @client.connect(@server.getsockname)
    end

    after do
      @client.close
      @server.close
    end

    describe 'without a destination address argument' do
      it 'returns the amount of bytes written' do
        @client.send('hello', 0).should == 5
      end
    end

    describe 'with a destination address argument' do
      before do
        @alt_server = Socket.new(:INET, :DGRAM)

        @alt_server.bind(Socket.sockaddr_in(0, '127.0.0.1'))
      end

      after do
        @alt_server.close
      end

      it 'sends the message to the given address instead' do
        @client.send('hello', 0, @alt_server.getsockname).should == 5

        SocketSpecs.blocking? { @server.recv(5) }.should == true

        @alt_server.recv(5).should == 'hello'
      end

      it 'does not persist the alternative connection after writing to the socket' do
        @client.send('hello', 0, @alt_server.getsockname)
        @client.send('world', 0)

        @server.recv(5).should == 'world'
      end
    end
  end

  describe 'using a connected TPC socket' do
    before do
      @client = Socket.new(:INET, :STREAM)
      @server = Socket.new(:INET, :STREAM)

      @server.bind(Socket.sockaddr_in(0, '127.0.0.1'))
      @server.listen(1)

      @client.connect(@server.getsockname)
    end

    after do
      @client.close
      @server.close
    end

    describe 'using the MSG_OOB flag' do
      it 'sends an out-of-band message' do
        @server.setsockopt(:SOCKET, :OOBINLINE, true)

        @client.send('a', Socket::MSG_OOB).should == 1

        socket, _ = @server.accept

        socket.recv(1, Socket::MSG_OOB).should == 'a'
      end
    end
  end
end
