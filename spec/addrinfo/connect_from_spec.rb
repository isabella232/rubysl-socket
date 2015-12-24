require 'socket'

describe 'Addrinfo#connect_from' do
  each_ip_protocol do |family, ip_address|
    before do
      @server = TCPServer.new(ip_address, 0)
      @port   = @server.connect_address.ip_port
    end

    after do
      @server.close
    end

    describe 'using separate arguments' do
      it 'returns a Socket when no block is given' do
        socket = Addrinfo.tcp(ip_address, @port).connect_from(ip_address, 0)

        socket.should be_an_instance_of(Socket)
      end

      it 'yields the Socket when a block is given' do
        Addrinfo.tcp(ip_address, @port).connect_from(ip_address, 0) do |socket|
          socket.should be_an_instance_of(Socket)
        end
      end

      it 'treats the last argument as a set of options if it is a Hash' do
        socket = Addrinfo.tcp(ip_address, @port)
          .connect_from(ip_address, 0, timeout: 2)

        socket.should be_an_instance_of(Socket)
      end

      it 'binds the socket to the local address' do
        socket = Addrinfo.tcp(ip_address, @port).connect_from(ip_address, 0)

        socket.local_address.ip_address.should == ip_address

        socket.local_address.ip_port.should > 0
        socket.local_address.ip_port.should_not == @port
      end
    end

    describe 'using an Addrinfo as the 1st argument' do
      before do
        @addr = Addrinfo.tcp(ip_address, 0)
      end

      it 'returns a Socket when no block is given' do
        socket = Addrinfo.tcp(ip_address, @port).connect_from(@addr)

        socket.should be_an_instance_of(Socket)
      end

      it 'yields the Socket when a block is given' do
        Addrinfo.tcp(ip_address, @port).connect_from(@addr) do |socket|
          socket.should be_an_instance_of(Socket)
        end
      end

      it 'treats the last argument as a set of options if it is a Hash' do
        socket = Addrinfo.tcp(ip_address, @port)
          .connect_from(@addr, timeout: 2)

        socket.should be_an_instance_of(Socket)
      end

      it 'binds the socket to the local address' do
        socket = Addrinfo.tcp(ip_address, @port).connect_from(@addr)

        socket.local_address.ip_address.should == ip_address

        socket.local_address.ip_port.should > 0
        socket.local_address.ip_port.should_not == @port
      end
    end
  end
end
