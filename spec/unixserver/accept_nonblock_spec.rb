require 'socket'

describe 'UNIXServer#accept_nonblock' do
  before do
    @path   = tmp('unix_socket')
    @server = UNIXServer.new(@path)
  end

  after do
    @server.close

    rm_r(@path)
  end

  describe 'without a client' do
    it 'raises IO::EAGAINWaitReadable' do
      proc { @server.accept_nonblock }
        .should raise_error(IO::EAGAINWaitReadable)
    end
  end

  describe 'with a client' do
    before do
      @client = UNIXSocket.new(@path)
    end

    after do
      @client.close
    end

    describe 'without any data' do
      it 'returns a UNIXSocket' do
        socket = @server.accept_nonblock

        begin
          socket.should be_an_instance_of(UNIXSocket)
        ensure
          socket.close
        end
      end
    end

    describe 'with data available' do
      before do
        @client.write('hello')
      end

      it 'returns a UNIXSocket' do
        socket = @server.accept_nonblock

        begin
          socket.should be_an_instance_of(UNIXSocket)
        ensure
          socket.close
        end
      end

      describe 'the returned UNIXSocket' do
        it 'can read the data written' do
          socket = @server.accept_nonblock

          begin
            socket.recv(5).should == 'hello'
          ensure
            socket.close
          end
        end
      end
    end
  end
end
