require 'socket'

describe 'BasicSocket#shutdown' do
  each_ip_protocol do |family, ip_address|
    before do
      @server = Socket.new(family, :STREAM)
      @client = Socket.new(family, :STREAM)

      @server.bind(Socket.sockaddr_in(0, ip_address))
      @server.listen(1)

      @client.connect(@server.getsockname)
    end

    after do
      @client.close
      @server.close
    end

    describe 'using a Fixnum' do
      it 'shuts down a socket for reading' do
        @server.shutdown(Socket::SHUT_RD)

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end

      it 'shuts down a socket for writing' do
        @client.shutdown(Socket::SHUT_WR)

        proc { @client.write('hello') }.should raise_error(Errno::EPIPE)
      end

      it 'shuts down a socket for reading and writing' do
        @server.shutdown(Socket::SHUT_RDWR)

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end

      it 'raises ArgumentError when using an invalid option' do
        proc { @server.shutdown(666) }.should raise_error(ArgumentError)
      end
    end

    describe 'using a Symbol' do
      it 'shuts down a socket for reading using :RD' do
        @server.shutdown(:RD)

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end

      it 'shuts down a socket for reading using :SHUT_RD' do
        @server.shutdown(:SHUT_RD)

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end

      it 'shuts down a socket for writing' do
        @client.shutdown(:WR)

        proc { @client.write('hello') }.should raise_error(Errno::EPIPE)
      end

      it 'shuts down a socket for reading and writing' do
        @server.shutdown(:RDWR)

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end

      it 'raises ArgumentError when using an invalid option' do
        proc { @server.shutdown(:Nope) }.should raise_error(SocketError)
      end
    end

    describe 'using a String' do
      it 'shuts down a socket for reading using "RD"' do
        @server.shutdown('RD')

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end

      it 'shuts down a socket for reading using "SHUT_RD"' do
        @server.shutdown('SHUT_RD')

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end

      it 'shuts down a socket for reading and writing' do
        @server.shutdown('RDWR')

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end

      it 'raises ArgumentError when using an invalid option' do
        proc { @server.shutdown('Nope') }.should raise_error(SocketError)
      end
    end

    describe 'using an object that responds to #to_str' do
      before do
        @dummy = mock(:dummy)
      end

      it 'shuts down a socket for reading using "RD"' do
        @dummy.stub!(:to_str).and_return('RD')

        @server.shutdown(@dummy)

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end

      it 'shuts down a socket for reading using "SHUT_RD"' do
        @dummy.stub!(:to_str).and_return('SHUT_RD')

        @server.shutdown(@dummy)

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end

      it 'shuts down a socket for reading and writing' do
        @dummy.stub!(:to_str).and_return('RDWR')

        @server.shutdown(@dummy)

        proc { @client.write('hello') }.should raise_error(Errno::ECONNRESET)
      end
    end

    describe 'using an object that does not respond to #to_str' do
      it 'raises TypeError' do
        proc { @server.shutdown(mock(:dummy)) }.should raise_error(TypeError)
      end
    end
  end
end
