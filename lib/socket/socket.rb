class Socket < BasicSocket
  include RubySL::Socket::ListenAndAccept

  def self.ip_address_list
    struct = RubySL::Socket::Foreign::Ifaddrs.new
    status = RubySL::Socket::Foreign.getifaddrs(struct)
    addrs  = []

    if status == -1
      raise "System call to getifaddrs() returned #{status.inspect}"
    end

    pointer = struct

    while pointer[:ifa_next]
      if pointer[:ifa_addr]
        addr   = RubySL::Socket::Foreign::Sockaddr.new(pointer[:ifa_addr])
        family = addr[:sa_family]

        if family == AF_INET or family == AF_INET6

          if AF_INET6
            size = family == RubySL::Socket::Foreign::Sockaddr_In6.size
          else
            size = family = RubySL::Socket::Foreign::Sockaddr_In.size
          end

          host = Rubinius::FFI::MemoryPointer.new(:char, Constants::NI_MAXHOST)

          status = RubySL::Socket::Foreign._getnameinfo(addr,
                                size,
                                host,
                                Socket::Constants::NI_MAXHOST,
                                nil,
                                0,
                                Constants::NI_NUMERICHOST)

          addrs << Addrinfo.ip(host.read_string)

          host.free
        end
      end

      pointer = RubySL::Socket::Foreign::Ifaddrs.new(pointer[:ifa_next])
    end

    RubySL::Socket::Foreign.freeifaddrs(struct)

    addrs
  end

  def self.getaddrinfo(host, service, family = 0, socktype = 0,
                       protocol = 0, flags = 0, reverse_lookup = nil)
    if service.kind_of?(Fixnum)
      service = service.to_s
    elsif service
      service = RubySL::Socket::Helpers.coerce_to_string(service)
    end

    family    = RubySL::Socket::Helpers.address_family(family)
    socktype  = RubySL::Socket::Helpers.socket_type(socktype)
    addrinfos = RubySL::Socket::Foreign
      .getaddrinfo(host, service, family, socktype, protocol, flags)

    reverse_lookup = RubySL::Socket::Helpers
      .convert_reverse_lookup(nil, reverse_lookup)

    addrinfos.map do |ai|
      addrinfo = []
      addrinfo << Socket::Constants::AF_TO_FAMILY[ai[1]]

      sockaddr = RubySL::Socket::Foreign
        .unpack_sockaddr_in(ai[4], reverse_lookup)

      addrinfo << sockaddr.pop  # port
      addrinfo.concat(sockaddr) # hosts

      addrinfo << ai[1]
      addrinfo << ai[2]
      addrinfo << ai[3]

      addrinfo
    end
  end

  def self.getnameinfo(sockaddr, flags = 0)
    port   = nil
    host   = nil
    family = Socket::AF_UNSPEC
    if sockaddr.is_a?(Array)
      if sockaddr.size == 3
        af = sockaddr[0]
        port = sockaddr[1]
        host = sockaddr[2]
      elsif sockaddr.size == 4
        af = sockaddr[0]
        port = sockaddr[1]
        host = sockaddr[3] || sockaddr[2]
      else
        raise ArgumentError, "array size should be 3 or 4, #{sockaddr.size} given"
      end

      if family == "AF_INET"
        family = Socket::AF_INET
      elsif family == "AF_INET6"
        family = Socket::AF_INET6
      end

      sockaddr = RubySL::Socket::Foreign
        .pack_sockaddr_in(host, port, family, Socket::SOCK_DGRAM, 0)
    end

    family, port, host, _ = RubySL::Socket::Foreign.getnameinfo(sockaddr, flags)

    [host, port]
  end

  def self.gethostname
    Rubinius::FFI::MemoryPointer.new :char, 1024 do |mp|  #magic number 1024 comes from MRI
      RubySL::Socket::Foreign.gethostname(mp, 1024) # same here
      return mp.read_string
    end
  end

  def self.gethostbyname(hostname)
    addrinfos = Socket.getaddrinfo(hostname, nil)

    hostname     = addrinfos.first[2]
    family       = addrinfos.first[4]
    addresses    = []
    alternatives = []
    addrinfos.each do |a|
      alternatives << a[2] unless a[2] == hostname
      # transform addresses to packed strings
      if a[4] == family
        sockaddr = Socket.sockaddr_in(1, a[3])
        if family == AF_INET
          # IPv4 address
          offset = Rubinius::FFI.config("sockaddr_in.sin_addr.offset")
          size = Rubinius::FFI.config("sockaddr_in.sin_addr.size")
          addresses << sockaddr.byteslice(offset, size)
        elsif family == AF_INET6
          # Ipv6 address
          offset = Rubinius::FFI.config("sockaddr_in6.sin6_addr.offset")
          size = Rubinius::FFI.config("sockaddr_in6.sin6_addr.size")
          addresses << sockaddr.byteslice(offset, size)
        else
          addresses << a[3]
        end
      end
    end

    [hostname, alternatives.uniq, family] + addresses.uniq
  end


  class Servent < Rubinius::FFI::Struct
    config("rbx.platform.servent", :s_name, :s_aliases, :s_port, :s_proto)

    def initialize(data)
      @p = Rubinius::FFI::MemoryPointer.new data.bytesize
      @p.write_string(data, data.bytesize)
      super(@p)
    end

    def to_s
      @p.read_string(size)
    end

  end

  def self.getservbyname(service, proto='tcp')
    Rubinius::FFI::MemoryPointer.new :char, service.length + 1 do |svc|
      Rubinius::FFI::MemoryPointer.new :char, proto.length + 1 do |prot|
        svc.write_string(service + "\0")
        prot.write_string(proto + "\0")
        fn = RubySL::Socket::Foreign.getservbyname(svc, prot)

        raise SocketError, "no such service #{service}/#{proto}" if fn.nil?

        s = Servent.new(fn.read_string(Servent.size))
        return RubySL::Socket::Foreign.ntohs(s[:s_port])
      end
    end
  end

  def self.pack_sockaddr_in(port, host, type = Socket::SOCK_DGRAM, flags = 0)
    RubySL::Socket::Foreign
      .pack_sockaddr_in(host, port, Socket::AF_UNSPEC, type, flags)
  end

  def self.unpack_sockaddr_in(sockaddr)
    _, address, port = RubySL::Socket::Foreign
      .unpack_sockaddr_in(sockaddr, false)

    return [port, address]
  rescue SocketError => e
    if e.message =~ /ai_family not supported/ then # HACK platform specific?
      raise ArgumentError, 'not an AF_INET/AF_INET6 sockaddr'
    else
      raise e
    end
  end

  def self.socketpair(domain, type, protocol, klass=self)
    if domain.kind_of? String
      if domain.prefix? "AF_" or domain.prefix? "PF_"
        begin
          domain = Socket::Constants.const_get(domain)
        rescue NameError
          raise SocketError, "unknown socket domain #{domani}"
        end
      else
        raise SocketError, "unknown socket domain #{domani}"
      end
    end

    type = RubySL::Socket::Helpers.socket_type(type)

    Rubinius::FFI::MemoryPointer.new :int, 2 do |mp|
      RubySL::Socket::Foreign.socketpair(domain, type, protocol, mp)
      fd0, fd1 = mp.read_array_of_int(2)

      [ klass.for_fd(fd0), klass.for_fd(fd1) ]
    end
  end

  class << self
    alias_method :sockaddr_in, :pack_sockaddr_in
    alias_method :pair, :socketpair
  end

  # Only define these methods if we support unix sockets
  if RubySL::Socket::Foreign.const_defined?(:Sockaddr_Un)
    def self.pack_sockaddr_un(file)
      RubySL::Socket::Foreign::Sockaddr_Un.new(file).to_s
    end

    def self.unpack_sockaddr_un(addr)

      if addr.bytesize > Rubinius::FFI.config("sockaddr_un.sizeof")
        raise TypeError, "too long sockaddr_un - #{addr.bytesize} longer than #{Rubinius::FFI.config("sockaddr_un.sizeof")}"
      end

      struct = RubySL::Socket::Foreign::Sockaddr_Un.new
      struct.pointer.write_string(addr, addr.bytesize)

      struct[:sun_path]
    end

    class << self
      alias_method :sockaddr_un, :pack_sockaddr_un
    end
  end

  def initialize(family, socket_type, protocol=0)
    @no_reverse_lookup = self.class.do_not_reverse_lookup
    @family = RubySL::Socket::Helpers.protocol_family(family)
    @socket_type = RubySL::Socket::Helpers.socket_type(socket_type)

    descriptor = RubySL::Socket::Foreign.socket(@family, @socket_type, protocol)

    Errno.handle 'socket(2)' if descriptor < 0

    IO.setup self, descriptor, nil, true
  end

  def bind(addr)
    if addr.is_a?(Addrinfo)
      addr = addr.to_sockaddr
    end

    err = RubySL::Socket::Foreign.bind(descriptor, addr)

    Errno.handle('bind(2)') unless err == 0

    0
  end

  def connect(sockaddr)
    status = RubySL::Socket::Foreign.connect(descriptor, sockaddr)

    Errno.handle('connect(2)') if status < 0

    0
  end

  def connect_nonblock(sockaddr)
    fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)

    status = RubySL::Socket::Foreign.connect(descriptor, sockaddr)

    Errno.handle('connect(2)') if status < 0

    0
  end

  def local_address
    sockaddr = RubySL::Socket::Foreign.getsockname(descriptor)

    Addrinfo.new(sockaddr, @family, @socket_type, 0)
  end

  def remote_address
    sockaddr = RubySL::Socket::Foreign.getpeername(descriptor)

    Addrinfo.new(sockaddr, @family, @socket_type, 0)
  end

  def recvfrom(bytes_to_read, flags = 0)
    bytes = socket_recv(bytes_to_read, flags, 0)
    addr  = Addrinfo.new(['AF_UNSPEC'], Socket::PF_UNSPEC, Socket::SOCK_STREAM)

    return bytes, addr
  end
end
