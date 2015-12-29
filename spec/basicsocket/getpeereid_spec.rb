require 'socket'

describe 'BasicSocket#getpeereid' do
  describe 'using a Socket' do
    before do
      @sock = Socket.new(:INET, :STREAM, 0)
    end

    # This only works because MRI implements getpereeid in BasicSocket, instead
    # of only implementing it for UnixSocket.
    #
    # On MRI this returns 4294967295 for both the euid and egid, but in case of
    # Rubinius this will return -1 for both.
    it 'returns seemingly random user and group IDs' do
      ids = @sock.getpeereid

      ids[0].should be_an_instance_of(Fixnum)
      ids[1].should be_an_instance_of(Fixnum)
    end
  end

  with_feature :unix_socket do
    describe 'using a UNIXSocket' do
      before do
        @path   = tmp('basic_socket_getpeereid_spec.sock', false)
        @server = UNIXServer.new(@path)
      end

      after do
        @server.close

        rm_r(@path)
      end

      it 'returns an Array with the user and group ID' do
        @server.getpeereid.should == [Process.euid, Process.egid]
      end
    end
  end

  describe 'using an IPSocket' do
    it 'raises NoMethodError' do
      sock = TCPServer.new('127.0.0.1', 0)

      proc { sock.getpeereid }.should raise_error(NoMethodError)
    end
  end
end
