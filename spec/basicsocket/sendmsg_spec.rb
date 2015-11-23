require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)

describe 'BasicSocket#sendmsg' do
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
        proc { @client.sendmsg('hello') }.should raise_error(Errno::EDESTADDRREQ)
      end
    end

    describe 'with a destination address' do
      it 'returns the amount of sent bytes' do
        @client.sendmsg('hello', 0, @server.getsockname).should == 5
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
        @client.sendmsg('hello').should == 5
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
        @client.sendmsg('hello', 0, @alt_server.getsockname).should == 5

        SocketSpecs.blocking? { @server.recv(5) }.should == true

        @alt_server.recv(5).should == 'hello'
      end
    end
  end

  describe 'using a connected TCP socket' do
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

    it 'blocks when the underlying buffer is full' do
      # Buffer sizes may differ per platform, so sadly this is the only
      # reliable way of testing blocking behaviour.
      blocking = SocketSpecs.blocking? do
        10.times { @client.sendmsg('hello' * 1_000_000) }
      end

      blocking.should == true
    end
  end
end
