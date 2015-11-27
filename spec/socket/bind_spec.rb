require 'socket'

describe 'Socket#bind' do
  describe 'using a packed socket address' do
    before do
      @socket   = Socket.new(:INET, :DGRAM)
      @sockaddr = Socket.sockaddr_in(0, '127.0.0.1')
    end

    after do
      @socket.close
    end

    it 'returns 0 when successfully bound' do
      @socket.bind(@sockaddr).should == 0
    end

    it 'raises Errno::EINVAL when binding to an already bound port' do
      @socket.bind(@sockaddr)

      proc { @socket.bind(@sockaddr) }.should raise_error(Errno::EINVAL)
    end

    it 'raises Errno::EADDRNOTAVAIL when the specified sockaddr is not available' do
      sockaddr1 = Socket.sockaddr_in(0, '4.3.2.1');

      proc { @socket.bind(sockaddr1); }.should raise_error(Errno::EADDRNOTAVAIL)
    end

    it 'raises Errno::EACCES when the user is not allowed to bind to the port' do
      sockaddr1 = Socket.pack_sockaddr_in(1, '127.0.0.1');

      proc { @socket.bind(sockaddr1); }.should raise_error(Errno::EACCES)
    end
  end

  describe 'using an Addrinfo' do
    before do
      @addr   = Addrinfo.udp('127.0.0.1', 0)
      @socket = Socket.new(@addr.afamily, @addr.socktype)
    end

    after do
      @socket.close
    end

    it 'binds to an Addrinfo' do
      @socket.bind(@addr).should == 0

      @socket.local_address.should be_an_instance_of(Addrinfo)
    end

    it 'uses a new Addrinfo for the local address' do
      @socket.bind(@addr)

      @socket.local_address.should_not == @addr
    end
  end
end
