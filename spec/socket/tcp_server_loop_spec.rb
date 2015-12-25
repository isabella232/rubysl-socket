require 'socket'

describe 'Socket.tcp_server_loop' do
  describe 'when no connections are available' do
    it 'blocks the caller' do
      proc { Socket.tcp_server_loop('127.0.0.1', 0) }.should block_caller
    end
  end

  describe 'when a connection is available' do
    before do
      @client = Socket.new(:INET, :STREAM)
      @port   = 9999
    end

    after do
      @client.close
    end

    it 'yields a Socket and an Addrinfo' do
      sock = nil
      addr = nil
      cvar = ConditionVariable.new
      lock = Mutex.new

      thread = Thread.new do
        Socket.tcp_server_loop('127.0.0.1', @port) do |socket, addrinfo|
          sock = socket
          addr = addrinfo

          break
        end

        lock.synchronize { cvar.signal }
      end

      # Normally one would use something like a ConditionVariable or a Channel,
      # sadly we wouldn't be able to to use this as we don't know when the TCP
      # server loop has started (only when it accepted a connection). This makes
      # it impossible to wait with connecting until it has started _without_
      # just waiting an arbitrary time.
      thread.join(2)

      @client.connect(Socket.sockaddr_in(@port, '127.0.0.1'))

      lock.synchronize { cvar.wait(lock) }

      sock.should be_an_instance_of(Socket)
      addr.should be_an_instance_of(Addrinfo)
    end
  end
end
