require 'socket'

describe 'Socket.udp_server_loop' do
  describe 'when no connections are available' do
    it 'blocks the caller' do
      proc { Socket.udp_server_loop('127.0.0.1', 0) }.should block_caller
    end
  end

  describe 'when a connection is available' do
    before do
      @client = Socket.new(:INET, :DGRAM)
      @port   = 9999
    end

    after do
      @client.close
    end

    it 'yields the message and a Socket::UDPSource' do
      msg  = nil
      src  = nil
      cvar = ConditionVariable.new
      lock = Mutex.new

      thread = Thread.new do
        Socket.udp_server_loop('127.0.0.1', @port) do |message, source|
          msg = message
          src = source

          break
        end

        lock.synchronize { cvar.signal }
      end

      # Normally one would use something like a ConditionVariable or a Channel,
      # sadly we wouldn't be able to to use this as we don't know when the UDP
      # server loop has started (only when it accepted a connection). This makes
      # it impossible to wait with connecting until it has started _without_
      # just waiting an arbitrary time.
      thread.join(2)

      @client.connect(Socket.sockaddr_in(@port, '127.0.0.1'))
      @client.write('hello')

      lock.synchronize { cvar.wait(lock) }

      msg.should == 'hello'
      src.should be_an_instance_of(Socket::UDPSource)
    end
  end
end
