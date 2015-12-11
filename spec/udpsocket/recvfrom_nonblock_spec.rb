require 'socket'

describe 'UDPSocket#recvfrom_nonblock' do
  before do
    @server = UDPSocket.new
    @client = UDPSocket.new
  end

  after do
    @client.close
    @server.close
  end

  describe 'using an unbound socket' do
    it 'raises IO::EAGAINWaitReadable' do
      proc { @server.recvfrom_nonblock(1) }
        .should raise_error(IO::EAGAINWaitReadable)
    end
  end

  describe 'using a bound socket' do
    before do
      @server.bind('127.0.0.1', 0)

      addr = @server.connect_address

      @client.connect(addr.ip_address, addr.ip_port)
    end

    describe 'without any data available' do
      it 'raises IO::EAGAINWaitReadable' do
        proc { @server.recvfrom_nonblock(1) }
          .should raise_error(IO::EAGAINWaitReadable)
      end
    end

    describe 'with data available' do
      before do
        @client.write('hello')
      end

      it 'returns an Array containing the data and an Array' do
        @server.recvfrom_nonblock(1).should be_an_instance_of(Array)
      end

      describe 'the returned Array' do
        before do
          @array = @server.recvfrom_nonblock(1)
        end

        it 'contains the data at index 0' do
          @array[0].should == 'h'
        end

        it 'contains an Array at index 1' do
          @array[1].should be_an_instance_of(Array)
        end
      end

      describe 'the returned address Array' do
        before do
          @addr = @server.recvfrom_nonblock(1)[1]
        end

        it 'uses AF_INET as the address family' do
          @addr[0].should == 'AF_INET'
        end

        it 'uses the IP address of the client' do
          @addr[2].should == '127.0.0.1'
        end

        it 'uses the port of the client' do
          @addr[1].should == @client.local_address.ip_port
        end
      end
    end
  end
end
