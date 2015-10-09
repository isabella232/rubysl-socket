class Addrinfo
  attr_reader :ip_port, :ip_address, :afamily, :pfamily, :socktype, :protocol,
    :unix_path

  def self.getaddrinfo(nodename, service, family = nil, socktype = nil,
                       protocol = nil, flags = nil)

    raw = Socket.getaddrinfo(nodename, service, family, socktype, protocol,
                             flags)

    raw.map do |pair|
      sockaddr = Socket.pack_sockaddr_in(pair[1], pair[3])

      Addrinfo.new(sockaddr, pair[0], pair[5], pair[6])
    end
  end

  def self.ip(ip)
    new(Socket.pack_sockaddr_in(nil, ip))
  end

  def self.tcp(ip, port)
    type  = Socket::SOCK_STREAM
    proto = Socket::IPPROTO_TCP

    new(Socket.pack_sockaddr_in(port, ip), nil, type, proto)
  end

  def self.udp(ip, port)
    type  = Socket::SOCK_DGRAM
    proto = Socket::IPPROTO_UDP

    new(Socket.pack_sockaddr_in(port, ip), nil, type, proto)
  end

  def self.unix(socket, socktype = nil)
    socktype ||= Socket::SOCK_STREAM

    new(Socket.pack_sockaddr_un(socket), nil, socktype)
  end

  def initialize(sockaddr, pfamily = nil, socktype = 0, protocol = 0)
    if sockaddr.kind_of?(Array)
      @afamily    = RubySL::Socket::Helpers.address_family(sockaddr[0])
      @ip_port    = sockaddr[1]
      @ip_address = sockaddr[3]
    else
      if sockaddr.bytesize == Rubinius::FFI.config('sockaddr_un.sizeof')
        @unix_path = Socket.unpack_sockaddr_un(sockaddr)
        @afamily   = Socket::AF_UNIX
      else
        @ip_port, @ip_address = Socket.unpack_sockaddr_in(sockaddr)

        @afamily = Socket::AF_INET
      end
    end

    @pfamily  = RubySL::Socket::Helpers.protocol_family(pfamily)
    @socktype = RubySL::Socket::Helpers.socket_type(socktype || 0)
    @protocol = protocol || 0

    # Per MRI behaviour setting the protocol family should also set the address
    # family, but only if the address and protocol families are compatible.
    if @pfamily && @pfamily != 0
      if @afamily == Socket::AF_INET6 and
      @pfamily != Socket::PF_INET and
      @pfamily != Socket::PF_INET6
        raise SocketError, 'Unsupported protocol family'
      end

      @afamily = @pfamily
    end

    # When using AF_INET6 the protocol family can only be PF_INET6
    if @afamily == Socket::AF_INET6
      @pfamily = Socket::PF_INET6
    end

    # MRI uses getaddrinfo() for this, but there's no need to do a system call
    # to check if the given address is in a valid format.
    #
    # MRI only checks this if "sockaddr" is an Array.
    if sockaddr.kind_of?(Array)
      if @afamily == Socket::AF_INET6 and @ip_address !~ Resolv::IPv6::Regex
        raise SocketError, "Invalid IPv6 address: #{@ip_address.inspect}"
      end
    end

    # Based on MRI's (re-)implementation of getaddrinfo()
    if @afamily != Socket::AF_UNIX and
    @afamily != Socket::PF_UNSPEC and
    @afamily != Socket::PF_INET and
    @afamily != Socket::PF_INET6
      raise SocketError, 'Unsupported address family'
    end

    # Per MRI this validation should only happen when "sockaddr" is an Array.
    if sockaddr.is_a?(Array)
      case @socktype
      when 0, nil
        case @protocol
        when 0, nil
          # nothing to do
        when Socket::IPPROTO_UDP
          @socktype = Socket::SOCK_DGRAM
        else
          raise SocketError, 'Unsupported protocol'
        end
      when Socket::SOCK_RAW
        # nothing to do
      when Socket::SOCK_DGRAM
        if @protocol != Socket::IPPROTO_UDP and @protocol != 0
          raise SocketError, 'Socket protocol must be IPPROTO_UDP or left unset'
        end
      when Socket::SOCK_STREAM
        if @protocol != Socket::IPPROTO_TCP and @protocol != 0
          raise SocketError, 'Socket protocol must be IPPROTO_TCP or left unset'
        end
      # Based on MRI behaviour, though MRI itself doesn't seem to explicitly
      # handle this case (possibly handled by getaddrinfo()).
      when Socket::SOCK_SEQPACKET
        if @protocol != 0
          raise SocketError, 'SOCK_SEQPACKET can not be used with an explicit protocol'
        end
      else
        raise SocketError, 'Unsupported socket type'
      end
    end
  end

  # Everything below is copied from the MRI codebase.

  # creates an Addrinfo object from the arguments.
  #
  # The arguments are interpreted as similar to self.
  #
  #   Addrinfo.tcp("0.0.0.0", 4649).family_addrinfo("www.ruby-lang.org", 80)
  #   #=> #<Addrinfo: 221.186.184.68:80 TCP (www.ruby-lang.org:80)>
  #
  #   Addrinfo.unix("/tmp/sock").family_addrinfo("/tmp/sock2")
  #   #=> #<Addrinfo: /tmp/sock2 SOCK_STREAM>
  #
  def family_addrinfo(*args)
    if args.empty?
      raise ArgumentError, "no address specified"
    elsif Addrinfo === args.first
      raise ArgumentError, "too many arguments" if args.length != 1
      addrinfo = args.first
      if (self.pfamily != addrinfo.pfamily) ||
         (self.socktype != addrinfo.socktype)
        raise ArgumentError, "Addrinfo type mismatch"
      end
      addrinfo
    elsif self.ip?
      raise ArgumentError, "IP address needs host and port but #{args.length} arguments given" if args.length != 2
      host, port = args
      Addrinfo.getaddrinfo(host, port, self.pfamily, self.socktype, self.protocol)[0]
    elsif self.unix?
      raise ArgumentError, "UNIX socket needs single path argument but #{args.length} arguments given" if args.length != 1
      path, = args
      Addrinfo.unix(path)
    else
      raise ArgumentError, "unexpected family"
    end
  end

  # creates a new Socket connected to the address of +local_addrinfo+.
  #
  # If _local_addrinfo_ is nil, the address of the socket is not bound.
  #
  # The _timeout_ specify the seconds for timeout.
  # Errno::ETIMEDOUT is raised when timeout occur.
  #
  # If a block is given the created socket is yielded for each address.
  #
  def connect_internal(local_addrinfo, timeout=nil) # :yields: socket
    sock = Socket.new(self.pfamily, self.socktype, self.protocol)
    begin
      sock.ipv6only! if self.ipv6?
      sock.bind local_addrinfo if local_addrinfo
      if timeout
        begin
          sock.connect_nonblock(self)
        rescue IO::WaitWritable
          if !IO.select(nil, [sock], nil, timeout)
            raise Errno::ETIMEDOUT, 'user specified timeout'
          end
          begin
            sock.connect_nonblock(self) # check connection failure
          rescue Errno::EISCONN
          end
        end
      else
        sock.connect(self)
      end
    rescue Exception
      sock.close
      raise
    end
    if block_given?
      begin
        yield sock
      ensure
        sock.close if !sock.closed?
      end
    else
      sock
    end
  end
  private :connect_internal

  # :call-seq:
  #   addrinfo.connect_from([local_addr_args], [opts]) {|socket| ... }
  #   addrinfo.connect_from([local_addr_args], [opts])
  #
  # creates a socket connected to the address of self.
  #
  # If one or more arguments given as _local_addr_args_,
  # it is used as the local address of the socket.
  # _local_addr_args_ is given for family_addrinfo to obtain actual address.
  #
  # If _local_addr_args_ is not given, the local address of the socket is not bound.
  #
  # The optional last argument _opts_ is options represented by a hash.
  # _opts_ may have following options:
  #
  # [:timeout] specify the timeout in seconds.
  #
  # If a block is given, it is called with the socket and the value of the block is returned.
  # The socket is returned otherwise.
  #
  #   Addrinfo.tcp("www.ruby-lang.org", 80).connect_from("0.0.0.0", 4649) {|s|
  #     s.print "GET / HTTP/1.0\r\nHost: www.ruby-lang.org\r\n\r\n"
  #     puts s.read
  #   }
  #
  #   # Addrinfo object can be taken for the argument.
  #   Addrinfo.tcp("www.ruby-lang.org", 80).connect_from(Addrinfo.tcp("0.0.0.0", 4649)) {|s|
  #     s.print "GET / HTTP/1.0\r\nHost: www.ruby-lang.org\r\n\r\n"
  #     puts s.read
  #   }
  #
  def connect_from(*args, &block)
    opts = Hash === args.last ? args.pop : {}
    local_addr_args = args
    connect_internal(family_addrinfo(*local_addr_args), opts[:timeout], &block)
  end

  # :call-seq:
  #   addrinfo.connect([opts]) {|socket| ... }
  #   addrinfo.connect([opts])
  #
  # creates a socket connected to the address of self.
  #
  # The optional argument _opts_ is options represented by a hash.
  # _opts_ may have following options:
  #
  # [:timeout] specify the timeout in seconds.
  #
  # If a block is given, it is called with the socket and the value of the block is returned.
  # The socket is returned otherwise.
  #
  #   Addrinfo.tcp("www.ruby-lang.org", 80).connect {|s|
  #     s.print "GET / HTTP/1.0\r\nHost: www.ruby-lang.org\r\n\r\n"
  #     puts s.read
  #   }
  #
  def connect(opts={}, &block)
    connect_internal(nil, opts[:timeout], &block)
  end

  # :call-seq:
  #   addrinfo.connect_to([remote_addr_args], [opts]) {|socket| ... }
  #   addrinfo.connect_to([remote_addr_args], [opts])
  #
  # creates a socket connected to _remote_addr_args_ and bound to self.
  #
  # The optional last argument _opts_ is options represented by a hash.
  # _opts_ may have following options:
  #
  # [:timeout] specify the timeout in seconds.
  #
  # If a block is given, it is called with the socket and the value of the block is returned.
  # The socket is returned otherwise.
  #
  #   Addrinfo.tcp("0.0.0.0", 4649).connect_to("www.ruby-lang.org", 80) {|s|
  #     s.print "GET / HTTP/1.0\r\nHost: www.ruby-lang.org\r\n\r\n"
  #     puts s.read
  #   }
  #
  def connect_to(*args, &block)
    opts = Hash === args.last ? args.pop : {}
    remote_addr_args = args
    remote_addrinfo = family_addrinfo(*remote_addr_args)
    remote_addrinfo.send(:connect_internal, self, opts[:timeout], &block)
  end

  # creates a socket bound to self.
  #
  # If a block is given, it is called with the socket and the value of the block is returned.
  # The socket is returned otherwise.
  #
  #   Addrinfo.udp("0.0.0.0", 9981).bind {|s|
  #     s.local_address.connect {|s| s.send "hello", 0 }
  #     p s.recv(10) #=> "hello"
  #   }
  #
  def bind
    sock = Socket.new(self.pfamily, self.socktype, self.protocol)
    begin
      sock.ipv6only! if self.ipv6?
      sock.setsockopt(:SOCKET, :REUSEADDR, 1)
      sock.bind(self)
    rescue Exception
      sock.close
      raise
    end
    if block_given?
      begin
        yield sock
      ensure
        sock.close if !sock.closed?
      end
    else
      sock
    end
  end

  # creates a listening socket bound to self.
  def listen(backlog=Socket::SOMAXCONN)
    sock = Socket.new(self.pfamily, self.socktype, self.protocol)
    begin
      sock.ipv6only! if self.ipv6?
      sock.setsockopt(:SOCKET, :REUSEADDR, 1)
      sock.bind(self)
      sock.listen(backlog)
    rescue Exception
      sock.close
      raise
    end
    if block_given?
      begin
        yield sock
      ensure
        sock.close if !sock.closed?
      end
    else
      sock
    end
  end

  # iterates over the list of Addrinfo objects obtained by Addrinfo.getaddrinfo.
  #
  #   Addrinfo.foreach(nil, 80) {|x| p x }
  #   #=> #<Addrinfo: 127.0.0.1:80 TCP (:80)>
  #   #   #<Addrinfo: 127.0.0.1:80 UDP (:80)>
  #   #   #<Addrinfo: [::1]:80 TCP (:80)>
  #   #   #<Addrinfo: [::1]:80 UDP (:80)>
  #
  def self.foreach(nodename, service, family=nil, socktype=nil, protocol=nil, flags=nil, &block)
    Addrinfo.getaddrinfo(nodename, service, family, socktype, protocol, flags).each(&block)
  end
end
