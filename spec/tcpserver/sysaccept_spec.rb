require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)

describe 'TCPServer#sysaccept' do
  before do
    @server = TCPServer.new('127.0.0.1', 0)
  end

  after do
    @server.close
  end

  describe 'without a connected client' do
    it 'blocks the caller' do
      SocketSpecs.blocking? { @server.sysaccept }.should == true
    end
  end

  describe 'with a connected client' do
    before do
      @client = TCPSocket.new('127.0.0.1', @server.connect_address.ip_port)
    end

    after do
      @client.close
    end

    it 'returns a new file descriptor as a Fixnum' do
      fd = @server.sysaccept

      fd.should be_an_instance_of(Fixnum)
      fd.should_not == @client.fileno
    end
  end
end
