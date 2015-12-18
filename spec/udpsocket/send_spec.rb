require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)

describe 'UDPSocket#send' do
  before do
    @server = UDPSocket.new
    @client = UDPSocket.new

    @server.bind('127.0.0.1', 0)

    @addr = @server.connect_address
  end

  after do
    @server.close
    @client.close
  end

  describe 'using a disconnected socket' do
    describe 'without a destination address' do
      it 'raises Errno::EDESTADDRREQ' do
        proc { @client.send('hello', 0) }
          .should raise_error(Errno::EDESTADDRREQ)
      end
    end

    describe 'with a destination address as separate arguments' do
      it 'returns the amount of sent bytes' do
        @client.send('hello', 0, @addr.ip_address, @addr.ip_port).should == 5
      end

      it 'does not persist the connection after sending data' do
        @client.send('hello', 0, @addr.ip_address, @addr.ip_port)

        proc { @client.send('hello', 0) }
          .should raise_error(Errno::EDESTADDRREQ)
      end
    end

    describe 'with a destination address as a single String argument' do
      it 'returns the amount of sent bytes' do
        @client.send('hello', 0, @server.getsockname).should == 5
      end
    end
  end

  describe 'using a connected socket' do
    before do
      @client.connect(@addr.ip_address, @addr.ip_port)
    end

    describe 'without an explicit destination address' do
      it 'returns the amount of bytes written' do
        @client.send('hello', 0).should == 5
      end
    end

    describe 'with an explicit destination address' do
      before do
        @alt_server = UDPSocket.new

        @alt_server.bind('127.0.0.1', 0)
      end

      after do
        @alt_server.close
      end

      it 'sends the data to the given address instead' do
        @client.send('hello', 0, @alt_server.getsockname).should == 5

        proc { @server.recv(5) }.should block_caller

        @alt_server.recv(5).should == 'hello'
      end
    end
  end
end
