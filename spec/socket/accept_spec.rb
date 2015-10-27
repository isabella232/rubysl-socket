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
      proc { @server.accept }.should raise_error(Errno::EINVAL)
    end
  end

  describe "using a bound socket that's not listening" do
    before do
      @server.bind(@sockaddr)
    end

    it 'raises Errno::EINVAL' do
      proc { @server.accept }.should raise_error(Errno::EINVAL)
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
          @server.accept
        end

        client.connect(@server_addr)

        SocketSpecs.join_thread!(thread)

        thread.value.should be_an_instance_of(Array)
      end
    end

    describe 'with a connected client' do
      it_behaves_like :socket_accept, :accept
    end
  end
end
