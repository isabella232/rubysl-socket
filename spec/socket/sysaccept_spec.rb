require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)
require File.expand_path('../../shared/accept', __FILE__)

describe 'Socket#accept' do
  before do
    @server   = Socket.new(:INET, :STREAM, 0)
    @sockaddr = Socket.sockaddr_in(0, '127.0.0.1')
  end

  after do
    @server.close
  end

  describe 'using an unbound socket'  do
    it 'raises Errno::EINVAL' do
      proc { @server.sysaccept }.should raise_error(Errno::EINVAL)
    end
  end

  describe "using a bound socket that's not listening" do
    before do
      @server.bind(@sockaddr)
    end

    it 'raises Errno::EINVAL' do
      proc { @server.sysaccept }.should raise_error(Errno::EINVAL)
    end
  end

  describe "using a bound socket that's listening" do
    before do
      @server.bind(@sockaddr)
      @server.listen(1)

      server_ip    = @server.local_address.ip_port
      @server_addr = Socket.sockaddr_in(server_ip, '127.0.0.1')
    end

    describe 'without a connected client' do
      it 'blocks the caller until a connection is available' do
        client = Socket.new(:INET, :STREAM, 0)
        thread = Thread.new do
          @server.sysaccept
        end

        client.connect(@server_addr)

        SocketSpecs.join_thread!(thread)

        thread.value.should be_an_instance_of(Array)
      end
    end

    describe 'with a connected client' do
      before do
        @client = Socket.new(:INET, :STREAM)

        @client.connect(@server.getsockname)
      end

      it 'returns an Array containing a Fixnum and an Addrinfo' do
        fd, addrinfo = @server.sysaccept

        fd.should be_an_instance_of(Fixnum)
        addrinfo.should be_an_instance_of(Addrinfo)
      end

      it 'returns a new file descriptor' do
        fd, _ = @server.sysaccept

        fd.should_not == @client.fileno
      end
    end
  end
end
