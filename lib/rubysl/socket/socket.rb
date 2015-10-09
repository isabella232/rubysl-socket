class Socket < BasicSocket
  module Constants
    all_valid = Rubinius::FFI.config_hash("socket").reject {|name, value| value.empty? }

    all_valid.each {|name, value| const_set name, Integer(value) }

    # MRI compat. socket is a pretty screwed up API. All the constants in Constants
    # must also be directly accessible on Socket itself. This means it's not enough
    # to include Constants into Socket, because Socket#const_defined? must be able
    # to see constants like AF_INET6 directly on Socket, but #const_defined? doesn't
    # check inherited constants. O_o
    #
    all_valid.each {|name, value| Socket.const_set name, Integer(value) }


    afamilies = all_valid.to_a.select { |name,| name =~ /^AF_/ }
    afamilies.map! {|name, value| [value.to_i, name] }

    pfamilies = all_valid.to_a.select { |name,| name =~ /^PF_/ }
    pfamilies.map! {|name, value| [value.to_i, name] }

    AF_TO_FAMILY = Hash[*afamilies.flatten]
    PF_TO_FAMILY = Hash[*pfamilies.flatten]
  end

  include RubySL::Socket::ListenAndAccept

  class Option
    attr_reader :family, :level, :optname, :data

    def self.bool(family, level, optname, bool)
      data = [(bool ? 1 : 0)].pack('i')
      new family, level, optname, data
    end

    def self.int(family, level, optname, integer)
      new family, level, optname, [integer].pack('i')
    end

    def self.linger(onoff, secs)
      linger = RubySL::Socket::Foreign::Linger.new

      case onoff
      when Integer
        linger[:l_onoff] = onoff
      else
        linger[:l_onoff] = onoff ? 1 : 0
      end
      linger[:l_linger] = secs

      p = linger.to_ptr
      data = p.read_string(p.total)

      new :UNSPEC, :SOCKET, :LINGER, data
    end

    def initialize(family, level, optname, data)
      @family = RubySL::Socket::Helpers.address_family(family)
      @family_name = family
      @level = level_arg(@family, level)
      @level_name = level
      @optname = optname_arg(@level, optname)
      @opt_name = optname
      @data = data
    end

    def unpack(template)
      @data.unpack template
    end

    def inspect
      "#<#{self.class}: #@family_name #@level_name #@opt_name #{@data.inspect}>"
    end

    def bool
      unless @data.length == Rubinius::Rubinius::FFI.type_size(:int)
        raise TypeError, "size differ. expected as sizeof(int)=" +
          "#{Rubinius::Rubinius::FFI.type_size(:int)} but #{@data.length}"
      end

      i = @data.unpack('i').first
      i == 0 ? false : true
    end

    def int
      unless @data.length == Rubinius::Rubinius::FFI.type_size(:int)
        raise TypeError, "size differ. expected as sizeof(int)=" +
          "#{Rubinius::Rubinius::FFI.type_size(:int)} but #{@data.length}"
      end
      @data.unpack('i').first
    end

    def linger
      if @level != Socket::SOL_SOCKET || @optname != Socket::SO_LINGER
        raise TypeError, "linger socket option expected"
      end
      if @data.bytesize != Rubinius::FFI.config("linger.sizeof")
        raise TypeError, "size differ. expected as sizeof(struct linger)=" +
          "#{Rubinius::FFI.config("linger.sizeof")} but #{@data.length}"
      end

      linger = RubySL::Socket::Foreign::Linger.new
      linger.to_ptr.write_string @data, @data.bytesize

      onoff = nil
      case linger[:l_onoff]
      when 0 then onoff = false
      when 1 then onoff = true
      else onoff = linger[:l_onoff].to_i
      end

      [onoff, linger[:l_linger].to_i]
    end

    alias :to_s :data

    private

    def level_arg(family, level)
      case level
      when Symbol, String
        if Socket::Constants.const_defined?(level)
          Socket::Constants.const_get(level)
        else
          if is_ip_family?(family)
            ip_level_to_int(level)
          else
            unknown_level_to_int(level)
          end
        end
      when Integer
        level
      else
        raise SocketError, "unknown protocol level: #{level}"
      end
    rescue NameError
      raise SocketError, "unknown protocol level: #{level}"
    end

    def optname_arg(level, optname)
      case optname
      when Symbol, String
        if Socket::Constants.const_defined?(optname)
          Socket::Constants.const_get(optname)
        else
          case(level)
          when Socket::Constants::SOL_SOCKET
            constant("SO", optname)
          when Socket::Constants::IPPROTO_IP
            constant("IP", optname)
          when Socket::Constants::IPPROTO_TCP
            constant("TCP", optname)
          when Socket::Constants::IPPROTO_UDP
            constant("UDP", optname)
          else
            if Socket::Constants.const_defined?(Socket::Constants::IPPROTO_IPV6) &&
                level == Socket::Constants::IPPROTO_IPV6
              constant("IPV6", optname)
            else
              optname
            end
          end
        end
      else
        optname
      end
    rescue NameError
      raise SocketError, "unknown socket level option name: #{optname}"
    end

    def is_ip_family?(family)
      [Socket::AF_INET, Socket::AF_INET6].include? family
    end

    def ip_level_to_int(level)
      prefixes = ["IPPROTO", "SOL"]
      prefixes.each do |prefix|
        if Socket::Constants.const_defined?("#{prefix}_#{level}")
          return Socket::Constants.const_get("#{prefix}_#{level}")
        end
      end
    end

    def unknown_level_to_int(level)
      constant("SOL", level)
    end

    def constant(prefix, suffix)
      #if Socket::Constants.const_defined?("#{prefix}_#{suffix}")
        Socket::Constants.const_get("#{prefix}_#{suffix}")
      #end
    end
  end

  # If we have the details to support unix sockets, do so.
  if Rubinius::FFI.config("sockaddr_un.sun_family.offset") and Socket::Constants.const_defined?(:AF_UNIX)
    class Sockaddr_Un < Rubinius::FFI::Struct
      config("rbx.platform.sockaddr_un", :sun_family, :sun_path)

      def initialize(filename = nil)
        maxfnsize = self.size - (Rubinius::FFI.config("sockaddr_un.sun_family.size") + 1)

        if filename and filename.length > maxfnsize
          raise ArgumentError, "too long unix socket path (max: #{maxfnsize}bytes)"
        end
        @p = Rubinius::FFI::MemoryPointer.new self.size
        if filename
          @p.write_string( [Socket::AF_UNIX].pack("s") + filename )
        end
        super @p
      end

      def to_s
        @p.read_string self.size
      end
    end
  end

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
                       protocol = 0, flags = 0)
    if service
      if service.kind_of?(Fixnum)
        service = service.to_s
      else
        service = StringValue(service)
      end
    end

    family    = RubySL::Socket::Helpers.address_family(family)
    socktype  = RubySL::Socket::Helpers.socket_type(socktype)
    addrinfos = RubySL::Socket::Foreign
      .getaddrinfo(host, service, family, socktype, protocol, flags)

    addrinfos.map do |ai|
      addrinfo = []
      addrinfo << Socket::Constants::AF_TO_FAMILY[ai[1]]

      sockaddr = RubySL::Socket::Foreign
        .unpack_sockaddr_in(ai[4], !BasicSocket.do_not_reverse_lookup)

      addrinfo << sockaddr.pop # port
      addrinfo.concat sockaddr # hosts
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

      [ klass.from_descriptor(fd0), klass.from_descriptor(fd1) ]
    end
  end

  class << self
    alias_method :sockaddr_in, :pack_sockaddr_in
    alias_method :pair, :socketpair
  end

  # Only define these methods if we support unix sockets
  if self.const_defined?(:Sockaddr_Un)
    def self.pack_sockaddr_un(file)
      Sockaddr_Un.new(file).to_s
    end

    def self.unpack_sockaddr_un(addr)

      if addr.bytesize > Rubinius::FFI.config("sockaddr_un.sizeof")
        raise TypeError, "too long sockaddr_un - #{addr.bytesize} longer than #{Rubinius::FFI.config("sockaddr_un.sizeof")}"
      end

      struct = Sockaddr_Un.new
      struct.pointer.write_string(addr, addr.bytesize)

      struct[:sun_path]
    end

    class << self
      alias_method :sockaddr_un, :pack_sockaddr_un
    end
  end

  def initialize(family, socket_type, protocol=0)
    @no_reverse_lookup = self.class.do_not_reverse_lookup
    family = RubySL::Socket::Helpers.protocol_family(family)
    socket_type = RubySL::Socket::Helpers.socket_type(socket_type)
    descriptor  = RubySL::Socket::Foreign.socket family, socket_type, protocol

    Errno.handle 'socket(2)' if descriptor < 0

    IO.setup self, descriptor, nil, true
  end

  def bind(server_sockaddr)
    err = RubySL::Socket::Foreign.bind(descriptor, server_sockaddr)
    Errno.handle 'bind(2)' unless err == 0
    err
  end

  def connect(sockaddr, extra=nil)
    if extra
      sockaddr = Socket.pack_sockaddr_in sockaddr, extra
    else
      sockaddr = StringValue(sockaddr)
    end

    status = RubySL::Socket::Foreign.connect descriptor, sockaddr

    if status < 0
      begin
        Errno.handle "connect(2)"
      rescue Errno::EISCONN
        return 0
      end
    end

    return 0
  end

  def connect_nonblock(sockaddr)
    fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)

    status = RubySL::Socket::Foreign.connect descriptor, StringValue(sockaddr)
    if status < 0
      Errno.handle "connect(2)"
    end

    return status
  end
end
