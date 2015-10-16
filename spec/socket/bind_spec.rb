require File.expand_path('../../fixtures/classes', __FILE__)

describe "Socket#bind on SOCK_DGRAM socket" do
  before do
    @sock = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM, 0);
    @sockaddr = Socket.pack_sockaddr_in(SocketSpecs.port, "127.0.0.1");
  end

  after do
    @sock.closed?.should be_false
    @sock.close
  end

  it "binds to a port" do
    lambda { @sock.bind(@sockaddr) }.should_not raise_error
  end

  it "returns 0 if successful" do
    @sock.bind(@sockaddr).should == 0
  end

  it "raises Errno::EINVAL when binding to an already bound port" do
    @sock.bind(@sockaddr);

    lambda { @sock.bind(@sockaddr); }.should raise_error(Errno::EINVAL);
  end

  it "raises Errno::EADDRNOTAVAIL when the specified sockaddr is not available from the local machine" do
    sockaddr1 = Socket.pack_sockaddr_in(SocketSpecs.port, "4.3.2.1");

    lambda { @sock.bind(sockaddr1); }.should raise_error(Errno::EADDRNOTAVAIL)
  end

  platform_is_not :os => [:windows, :cygwin] do
    it "raises Errno::EACCES when the current user does not have permission to bind" do
      sockaddr1 = Socket.pack_sockaddr_in(1, "127.0.0.1");

      lambda { @sock.bind(sockaddr1); }.should raise_error(Errno::EACCES)
    end
  end
end

describe "Socket#bind on SOCK_STREAM socket" do
  before do
    @sock = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0);
    @sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)

    @sockaddr = Socket.pack_sockaddr_in(SocketSpecs.port, "127.0.0.1");
  end

  after do
    @sock.closed?.should be_false
    @sock.close
  end

  it "binds to a port" do
    lambda { @sock.bind(@sockaddr) }.should_not raise_error
  end

  it "returns 0 if successful" do
    @sock.bind(@sockaddr).should == 0
  end

  it "raises Errno::EINVAL when binding to an already bound port" do
    @sock.bind(@sockaddr);

    lambda { @sock.bind(@sockaddr); }.should raise_error(Errno::EINVAL);
  end

  it "raises Errno::EADDRNOTAVAIL when the specified sockaddr is not available from the local machine" do
    sockaddr1 = Socket.pack_sockaddr_in(SocketSpecs.port, "4.3.2.1");

    lambda { @sock.bind(sockaddr1); }.should raise_error(Errno::EADDRNOTAVAIL)
  end

  platform_is_not :os => [:windows, :cygwin] do
    it "raises Errno::EACCES when the current user does not have permission to bind" do
      sockaddr1 = Socket.pack_sockaddr_in(1, "127.0.0.1");

      lambda { @sock.bind(sockaddr1); }.should raise_error(Errno::EACCES)
    end
  end
end

describe 'Socket#bind using an Addrinfo' do
  before do
    @addr = Addrinfo.tcp('127.0.0.1', 9999)
    @sock = Socket.new(@addr.afamily, @addr.socktype)
  end

  after do
    @sock.close
  end

  it 'binds to an Addrinfo' do
    @sock.bind(@addr)

    @sock.local_address.should be_an_instance_of(Addrinfo)
  end

  it 'uses a new Addrinfo for the local address' do
    @sock.bind(@addr)

    @sock.local_address.should_not == @addr
  end

  describe 'the Addrinfo used as the local address' do
    before do
      @sock.bind(@addr)
    end

    it 'has the same address family' do
      @sock.local_address.afamily.should == @addr.afamily
    end

    it 'has the same protocol family' do
      @sock.local_address.pfamily.should == @addr.pfamily
    end

    it 'has the same socket type' do
      @sock.local_address.socktype.should == @addr.socktype
    end
  end
end
