require 'socket'

describe 'Socket.unix_server_loop' do
  before do
    @path = tmp('unix_socket')
  end

  after do
    rm_r(@path)
  end

  describe 'when no connections are available' do
    it 'blocks the caller' do
      proc { Socket.unix_server_loop(@path) }.should block_caller
    end
  end

  describe 'when a connection is available' do
    before do
      @client = nil
    end

    after do
      @client.close if @client
    end

    it 'yields a Socket and an Addrinfo' do
      sock = nil
      addr = nil
      cvar = ConditionVariable.new
      lock = Mutex.new

      thread = Thread.new do
        Socket.unix_server_loop(@path) do |socket, addrinfo|
          sock = socket
          addr = addrinfo

          break
        end

        lock.synchronize { cvar.signal }
      end

      thread.join(2)

      @client = Socket.unix(@path)

      lock.synchronize { cvar.wait(lock) }

      sock.should be_an_instance_of(Socket)
      addr.should be_an_instance_of(Addrinfo)
    end
  end
end
