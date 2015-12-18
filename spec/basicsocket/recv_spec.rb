require 'socket'
require File.expand_path('../../fixtures/classes', __FILE__)

describe 'BasicSocket#recv' do
  describe 'using IPv4' do
    before do
      @server = Socket.new(:INET, :DGRAM)
      @client = Socket.new(:INET, :DGRAM)
    end

    after do
      @client.close
      @server.close
    end

    describe 'using an unbound socket' do
      it 'blocks the caller' do
        SocketSpecs.blocking? { @server.recv(4) }.should == true
      end
    end

    describe 'using a bound socket' do
      before do
        @server.bind(Socket.sockaddr_in(0, '127.0.0.1'))
      end

      describe 'without any data available' do
        it 'blocks the caller' do
          SocketSpecs.blocking? { @server.recv(4) }.should == true
        end
      end

      describe 'with data available' do
        before do
          @client.connect(@server.getsockname)
        end

        it 'reads the given amount of bytes' do
          @client.write('hello')

          @server.recv(2).should == 'he'
        end

        it 'reads the given amount of bytes when it exceeds the data size' do
          @client.write('he')

          @server.recv(6).should == 'he'
        end

        it 'blocks the caller when called twice without new data being available' do
          @client.write('hello')

          @server.recv(2).should == 'he'

          SocketSpecs.blocking? { @server.recv(4) }.should == true
        end

        it 'takes a peek at the data when using the MSG_PEEK flag' do
          @client.write('hello')

          @server.recv(2, Socket::MSG_PEEK).should == 'he'
          @server.recv(2).should == 'he'
        end
      end
    end
  end

  describe 'using IPv6' do
    before do
      @server = Socket.new(:INET6, :DGRAM)
      @client = Socket.new(:INET6, :DGRAM)
    end

    after do
      @client.close
      @server.close
    end

    describe 'using a bound socket with data available' do
      before do
        @server.bind(Socket.sockaddr_in(0, '::1'))
        @client.connect(@server.getsockname)
      end

      it 'reads the given amount of bytes' do
        @client.write('hello')

        @server.recv(2).should == 'he'
      end
    end
  end
end
