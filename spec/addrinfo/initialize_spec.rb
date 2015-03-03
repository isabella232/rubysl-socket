require 'socket'

describe 'Addrinfo#initialize' do
  describe 'using separate arguments for a TCP socket' do
    before do
      @sockaddr = Socket.sockaddr_in(80, '127.0.0.1')
    end

    it 'returns an Addrinfo with the correct IP' do
      addr = Addrinfo.new(@sockaddr)

      addr.ip_address.should == '127.0.0.1'
    end

    it 'returns an Addrinfo with the correct port' do
      addr = Addrinfo.new(@sockaddr)

      addr.ip_port.should == 80
    end

    it 'returns an Addrinfo with AF_INET as the default address family' do
      addr = Addrinfo.new(@sockaddr)

      addr.afamily.should == Socket::AF_INET
    end

    it 'returns an Addrinfo with PF_UNSPEC as the default protocol family' do
      addr = Addrinfo.new(@sockaddr)

      addr.pfamily.should == Socket::PF_UNSPEC
    end

    it 'returns an Addrinfo with PF_INET6 as the protocol family' do
      addr = Addrinfo.new(@sockaddr, Socket::PF_INET6)

      addr.pfamily.should == Socket::PF_INET6
    end

    it 'returns an Addrinfo with the correct socket type' do
      addr = Addrinfo.new(@sockaddr, nil, Socket::SOCK_STREAM)

      addr.socktype.should == Socket::SOCK_STREAM
    end

    it 'returns an Addrinfo with the correct protocol' do
      addr = Addrinfo.new(@sockaddr, nil, 0, Socket::IPPROTO_TCP)

      addr.protocol.should == Socket::IPPROTO_TCP
    end

    describe 'with Symbols' do
      it 'returns an Addrinfo with :PF_INET as the protocol family' do
        addr = Addrinfo.new(@sockaddr, :PF_INET)

        addr.pfamily.should == Socket::PF_INET
      end

      it 'returns an Addrinfo with :INET as the protocol family' do
        addr = Addrinfo.new(@sockaddr, :INET)

        addr.pfamily.should == Socket::PF_INET
      end

      it 'returns an Addrinfo with :SOCK_STREAM as the socket type' do
        addr = Addrinfo.new(@sockaddr, nil, :SOCK_STREAM)

        addr.socktype.should == Socket::SOCK_STREAM
      end

      it 'returns an Addrinfo with :STREAM as the socket type' do
        addr = Addrinfo.new(@sockaddr, nil, :STREAM)

        addr.socktype.should == Socket::SOCK_STREAM
      end
    end

    describe 'with Strings' do
      it 'returns an Addrinfo with "PF_INET" as the protocol family' do
        addr = Addrinfo.new(@sockaddr, 'PF_INET')

        addr.pfamily.should == Socket::PF_INET
      end

      it 'returns an Addrinfo with "INET" as the protocol family' do
        addr = Addrinfo.new(@sockaddr, 'INET')

        addr.pfamily.should == Socket::PF_INET
      end

      it 'returns an Addrinfo with "SOCK_STREAM" as the socket type' do
        addr = Addrinfo.new(@sockaddr, nil, 'SOCK_STREAM')

        addr.socktype.should == Socket::SOCK_STREAM
      end

      it 'returns an Addrinfo with "STREAM" as the socket type' do
        addr = Addrinfo.new(@sockaddr, nil, 'STREAM')

        addr.socktype.should == Socket::SOCK_STREAM
      end
    end
  end

  describe 'using separate arguments for a Unix socket' do
    before do
      @sockaddr = Socket.pack_sockaddr_un('socket')
    end

    it 'returns an Addrinfo with the correct unix path' do
      Addrinfo.new(@sockaddr).unix_path.should == 'socket'
    end

    it 'returns an Addrinfo with the correct protocol family' do
      Addrinfo.new(@sockaddr).pfamily.should == Socket::PF_UNSPEC
    end

    it 'returns an Addrinfo with the correct address family' do
      Addrinfo.new(@sockaddr).afamily.should == Socket::AF_UNIX
    end
  end

  describe 'using an Array as a single argument' do
    # Uses AF_INET6 since AF_INET is the default, making it harder to test if
    # our Addrinfo actually sets the family correctly.
    before do
      @sockaddr = ['AF_INET6', 80, 'hostname', '::1']
    end

    it 'returns an Addrinfo with the correct IP' do
      addr = Addrinfo.new(@sockaddr)

      addr.ip_address.should == '::1'
    end

    it 'returns an Addrinfo with the correct address family' do
      addr = Addrinfo.new(@sockaddr)

      addr.afamily.should == Socket::AF_INET6
    end

    it 'returns an Addrinfo with the correct protocol family' do
      addr = Addrinfo.new(@sockaddr)

      addr.pfamily.should == Socket::PF_INET6
    end

    it 'returns an Addrinfo with the correct port' do
      addr = Addrinfo.new(@sockaddr)

      addr.ip_port.should == 80
    end
  end
end
