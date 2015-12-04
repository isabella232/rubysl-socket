require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)

describe 'TCPServer#accept' do
  before do
    @server = TCPServer.new('127.0.0.1', 0)
  end

  after do
    @server.close
  end

  describe 'without a connected client' do
    it 'blocks the caller' do
      SocketSpecs.blocking? { @server.accept }.should == true
    end
  end

  describe 'with a connected client' do
    before do
      @client = TCPSocket.new('127.0.0.1', @server.connect_address.ip_port)
    end

    after do
      @client.close
    end

    it 'returns a TCPSocket' do
      @server.accept.should be_an_instance_of(TCPSocket)
    end
  end
end
