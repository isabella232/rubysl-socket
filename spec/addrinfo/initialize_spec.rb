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
    describe 'using a valid address' do
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

    describe 'using an invalid address' do
      it 'raises SocketError' do
        block = proc { Addrinfo.new(['AF_INET6', 80, 'hostname', '127.0.0.1']) }

        block.should raise_error(SocketError)
      end
    end
  end

  describe 'using an Array with extra arguments' do
    describe 'using AF_INET with an explicit protocol family' do
      before do
        @sockaddr = ['AF_INET', 80, 'hostname', '127.0.0.1']
      end

      it 'raises SocketError when setting the protocol family to PF_APPLETALK' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_APPLETALK) }

        block.should raise_error(SocketError)
      end

      it 'overwrites the protocol family when using PF_AX25' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_AX25) }

        block.should raise_error(SocketError)
      end

      it 'keeps the protocol family as-is when using PF_INET' do
        addr = Addrinfo.new(@sockaddr, Socket::PF_INET)

        addr.pfamily.should == Socket::PF_INET
      end

      it 'raises SocketError when setting the protocol family to PF_INET6' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_INET6) }

        block.should raise_error(SocketError)
      end

      it 'raises SocketError when setting the protocol family to PF_IPX' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_IPX) }

        block.should raise_error(SocketError)
      end

      it 'raises SocketError when setting the protocol family to PF_KEY' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_KEY) }

        block.should raise_error(SocketError)
      end

      it 'raises SocketError when setting the protocol family to PF_MAX' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_MAX) }

        block.should raise_error(SocketError)
      end

      it 'raises SocketError when setting the protocol family to PF_ROUTE' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_ROUTE) }

        block.should raise_error(SocketError)
      end

      it 'raises SocketError when setting the protocol family to PF_UNIX' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_UNIX) }

        block.should raise_error(SocketError)
      end

      it 'raises SocketError when setting the protocol family to PF_ISDN' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_ISDN) }

        block.should raise_error(SocketError)
      end

      it 'raises SocketError when setting the protocol family to PF_LOCAL' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_LOCAL) }

        block.should raise_error(SocketError)
      end

      it 'raises SocketError when setting the protocol family to PF_PACKET' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_PACKET) }

        block.should raise_error(SocketError)
      end

      it 'raises SocketError when setting the protocol family to PF_SNA' do
        block = proc { Addrinfo.new(@sockaddr, Socket::PF_SNA) }

        block.should raise_error(SocketError)
      end

      it 'overwrites the protocol family with PF_INET when using PF_UNSPEC' do
        addr = Addrinfo.new(@sockaddr, Socket::PF_UNSPEC)

        addr.pfamily.should == Socket::PF_INET
      end
    end

    describe 'using AF_INET with an explicit socket type' do
      before do
        @sockaddr = ['AF_INET', 80, 'hostname', '127.0.0.1']
      end

      it 'overwrites the socket type when using SOCK_DGRAM' do
        addr = Addrinfo.new(@sockaddr, nil, Socket::SOCK_DGRAM)

        addr.socktype.should == Socket::SOCK_DGRAM
      end

      it 'raises SocketError when using SOCK_PACKET' do
        block = proc { Addrinfo.new(@sockaddr, nil, Socket::SOCK_PACKET) }

        block.should raise_error(SocketError)
      end

      it 'overwrites the socket type hwne using SOCK_RAW' do
        addr = Addrinfo.new(@sockaddr, nil, Socket::SOCK_RAW)

        addr.socktype.should == Socket::SOCK_RAW
      end

      it 'raises SocketError when using SOCK_RDM' do
        block = proc { Addrinfo.new(@sockaddr, nil, Socket::SOCK_RDM) }

        block.should raise_error(SocketError)
      end
    end

    describe 'using AF_INET with an explicit protocol' do
      before do
        @sockaddr = ['AF_INET', 80, 'hostname', '127.0.0.1']
      end

      it 'overwrites the protocol when using IPPROTO_IP' do
        addr = Addrinfo.new(@sockaddr, nil, nil, Socket::IPPROTO_IP)

        addr.protocol.should == Socket::IPPROTO_IP
      end

      it 'raises SocketError when using IPPROTO_ICMP' do
        block = proc { Addrinfo.new(@sockaddr, nil, nil, Socket::IPPROTO_ICMP) }

        block.should raise_error(SocketError)
      end
    end
  end
end
