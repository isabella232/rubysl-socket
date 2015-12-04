require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)
require File.expand_path('../../shared/accept', __FILE__)

describe 'Socket#accept_nonblock' do
  before do
    @server   = Socket.new(:INET, :STREAM, 0)
    @sockaddr = Socket.sockaddr_in(0, '127.0.0.1')
  end

  after do
    @server.close unless @server.closed?
  end

  describe 'using an unbound socket' do
    it 'raises Errno::EINVAL' do
      proc { @server.accept_nonblock }.should raise_error(Errno::EINVAL)
    end
  end

  describe "using a bound socket that's not listening" do
    before do
      @server.bind(@sockaddr)
    end

    it 'raises Errno::EINVAL' do
      proc { @server.accept_nonblock }.should raise_error(Errno::EINVAL)
    end
  end

  describe 'using a closed socket' do
    it 'raises IOError' do
      @server.close

      proc { @server.accept_nonblock }.should raise_error(IOError)
    end
  end

  describe "using a bound socket that's listening" do
    before do
      @server.bind(@sockaddr)
      @server.listen(1)
    end

    describe 'without a connected client' do
      it 'raises IO::EAGAINWaitReadable' do
        proc { @server.accept_nonblock }.should raise_error(IO::EAGAINWaitReadable)
      end
    end

    describe 'with a connected client' do
      it_behaves_like :socket_accept, :accept_nonblock
    end
  end
end
