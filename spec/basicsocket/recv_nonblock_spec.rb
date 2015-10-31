require 'socket'

describe 'BasicSocket#recv_nonblock' do
  before do
    @server = Socket.new(:INET, :DGRAM)
    @client = Socket.new(:INET, :DGRAM)
  end

  after do
    @client.close
    @server.close
  end

  describe 'using an unbound socket' do
    it 'raises IO::EAGAINWaitReadable' do
      proc { @server.recv_nonblock(1) }
        .should raise_error(IO::EAGAINWaitReadable)
    end
  end

  describe 'using a bound socket' do
    before do
      @server.bind(Socket.sockaddr_in(0, '127.0.0.1'))

      @client.connect(@server.getsockname)
    end

    describe 'without any data available' do
      it 'raises IO::EAGAINWaitReadable' do
        proc { @server.recv_nonblock(1) }
          .should raise_error(IO::EAGAINWaitReadable)
      end
    end

    describe 'with data available' do
      it 'returns the given amount of bytes' do
        @client.write('hello')

        @server.recv_nonblock(2).should == 'he'
      end
    end
  end
end
