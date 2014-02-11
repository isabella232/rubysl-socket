require File.expand_path('../../fixtures/classes', __FILE__)

describe "UDPSocket.send" do
  before :each do
    @ready = false
    @server_thread = Thread.new do
      @server = UDPSocket.open
      @server.bind(nil, SocketSpecs.port)
      @ready = true
      begin
        @msg = @server.recvfrom_nonblock(64)
      rescue Errno::EAGAIN
        IO.select([@server])
        retry
      end
      @server.close
    end
    Thread.pass while @server_thread.status and !@ready
  end

  after :each do
    @socket.close if @socket and !@socket.closed?
  end

  it "sends data in ad hoc mode" do
    @socket = UDPSocket.open
    @socket.send("ad hoc", 0, SocketSpecs.hostname,SocketSpecs.port)
    @socket.close
    @server_thread.join

    @msg[0].should == "ad hoc"
    @msg[1][0].should == "AF_INET"
    @msg[1][1].should be_kind_of(Fixnum)
    @msg[1][3].should == "127.0.0.1"
  end

  it "sends data in ad hoc mode (with port given as a String)" do
    @socket = UDPSocket.open
    @socket.send("ad hoc", 0, SocketSpecs.hostname,SocketSpecs.str_port)
    @socket.close
    @server_thread.join

    @msg[0].should == "ad hoc"
    @msg[1][0].should == "AF_INET"
    @msg[1][1].should be_kind_of(Fixnum)
    @msg[1][3].should == "127.0.0.1"
  end

  it "sends data in connection mode" do
    @socket = UDPSocket.open
    @socket.connect(SocketSpecs.hostname,SocketSpecs.port)
    @socket.send("connection-based", 0)
    @socket.close
    @server_thread.join

    @msg[0].should == "connection-based"
    @msg[1][0].should == "AF_INET"
    @msg[1][1].should be_kind_of(Fixnum)
    @msg[1][3].should == "127.0.0.1"
  end

  it "returns the length of the message in bytes and ignores errors sending data when the socket is not connected" do
    @socket = UDPSocket.open
    @socket.send("this", 0, "127.0.0.1", SocketSpecs.port + 1).should == 4
    @socket.send("is", 0, "127.0.0.1", SocketSpecs.port + 1).should == 2
    @socket.send("nonsense", 0, "127.0.0.1", SocketSpecs.port + 1).should == 8
  end
end
