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

  module Foreign
    extend Rubinius::FFI::Library

    class Addrinfo < Rubinius::FFI::Struct
      config("rbx.platform.addrinfo", :ai_flags, :ai_family, :ai_socktype,
             :ai_protocol, :ai_addrlen, :ai_addr, :ai_canonname, :ai_next)
    end

    class Linger < Rubinius::FFI::Struct
      config("rbx.platform.linger", :l_onoff, :l_linger)
    end

    class Ifaddrs < Rubinius::FFI::Struct
      config(
        "rbx.platform.ifaddrs",
        :ifa_next, :ifa_name, :ifa_flags, :ifa_addr, :ifa_netmask
      )
    end

    class Sockaddr < Rubinius::FFI::Struct
      config("rbx.platform.sockaddr", :sa_data, :sa_family)
    end

    attach_function :_bind,    "bind", [:int, :pointer, :socklen_t], :int
    attach_function :_connect, "connect", [:int, :pointer, :socklen_t], :int

    attach_function :accept,   [:int, :pointer, :pointer], :int
    attach_function :close,    [:int], :int
    attach_function :shutdown, [:int, :int], :int
    attach_function :listen,   [:int, :int], :int
    attach_function :socket,   [:int, :int, :int], :int
    attach_function :send,     [:int, :pointer, :size_t, :int], :ssize_t
    attach_function :recv,     [:int, :pointer, :size_t, :int], :ssize_t
    attach_function :recvfrom, [:int, :pointer, :size_t, :int,
                                :pointer, :pointer], :int

    attach_function :_getsockopt,
                    "getsockopt", [:int, :int, :int, :pointer, :pointer], :int
    attach_function :_getaddrinfo,
                    "getaddrinfo", [:string, :string, :pointer, :pointer], :int

    attach_function :gai_strerror,  [:int], :string
    attach_function :setsockopt,    [:int, :int, :int, :pointer, :socklen_t], :int
    attach_function :freeaddrinfo,  [:pointer], :void
    attach_function :_getpeername,  "getpeername", [:int, :pointer, :pointer], :int
    attach_function :_getsockname,  "getsockname", [:int, :pointer, :pointer], :int

    attach_function :socketpair,    [:int, :int, :int, :pointer], :int

    attach_function :gethostname,   [:pointer, :size_t], :int
    attach_function :getservbyname, [:pointer, :pointer], :pointer

    attach_function :htons,         [:uint16_t], :uint16_t
    attach_function :ntohs,         [:uint16_t], :uint16_t

    attach_function :_getnameinfo,
                    "getnameinfo", [:pointer, :socklen_t, :pointer, :socklen_t,
                                    :pointer, :socklen_t, :int], :int

    attach_function :getifaddrs, [:pointer], :int
    attach_function :freeifaddrs, [:pointer], :void

    def self.bind(descriptor, sockaddr)
      Rubinius::FFI::MemoryPointer.new :char, sockaddr.bytesize do |sockaddr_p|
        sockaddr_p.write_string sockaddr, sockaddr.bytesize

        _bind descriptor, sockaddr_p, sockaddr.bytesize
      end
    end

    def self.connect(descriptor, sockaddr)
      err = 0
      Rubinius::FFI::MemoryPointer.new :char, sockaddr.bytesize do |sockaddr_p|
        sockaddr_p.write_string sockaddr, sockaddr.bytesize

        err = _connect descriptor, sockaddr_p, sockaddr.bytesize
      end

      err
    end

    def self.getsockopt(descriptor, level, optname)
      Rubinius::FFI::MemoryPointer.new 256 do |val| # HACK magic number
        Rubinius::FFI::MemoryPointer.new :socklen_t do |length|
          length.write_int 256 # HACK magic number

          err = _getsockopt descriptor, level, optname, val, length

          Errno.handle "Unable to get socket option" unless err == 0

          return val.read_string(length.read_int)
        end
      end
    end

    def self.getaddrinfo(host, service = nil, family = nil, socktype = nil,  protocol = nil, flags = nil)
      hints = Addrinfo.new
      hints[:ai_family] = family || 0
      hints[:ai_socktype] = socktype || 0
      hints[:ai_protocol] = protocol || 0
      hints[:ai_flags] = flags || 0

      if host && (host.empty? || host == '<any>')
        host = "0.0.0.0"
      elsif host == '<broadcast>'
        host = '255.255.255.255'
      end

      res_p = Rubinius::FFI::MemoryPointer.new :pointer

      err = _getaddrinfo host, service, hints.pointer, res_p

      raise SocketError, gai_strerror(err) unless err == 0

      ptr = res_p.read_pointer

      return [] unless ptr

      res = Addrinfo.new ptr

      addrinfos = []

      while true
        addrinfo = []
        addrinfo << res[:ai_flags]
        addrinfo << res[:ai_family]
        addrinfo << res[:ai_socktype]
        addrinfo << res[:ai_protocol]
        addrinfo << res[:ai_addr].read_string(res[:ai_addrlen])
        addrinfo << res[:ai_canonname]

        addrinfos << addrinfo

        break unless res[:ai_next]

        res = Addrinfo.new res[:ai_next]
      end

      return addrinfos
    ensure
      hints.free if hints

      if res_p
        ptr = res_p.read_pointer

        # Be sure to feed a legit pointer to freeaddrinfo
        if ptr and !ptr.null?
          freeaddrinfo ptr
        end
        res_p.free
      end
    end

    def self.getaddress(host)
      addrinfos = getaddrinfo(host)
      unpack_sockaddr_in(addrinfos.first[4], false).first
    end

    def self.getnameinfo(sockaddr, flags = Socket::Constants::NI_NUMERICHOST | Socket::Constants::NI_NUMERICSERV,
                         reverse_lookup = !BasicSocket.do_not_reverse_lookup)
      name_info = []
      value = nil

      Rubinius::FFI::MemoryPointer.new :char, sockaddr.bytesize do |sockaddr_p|
        Rubinius::FFI::MemoryPointer.new :char, Socket::Constants::NI_MAXHOST do |node|
          Rubinius::FFI::MemoryPointer.new :char, Socket::Constants::NI_MAXSERV do |service|
            sockaddr_p.write_string sockaddr, sockaddr.bytesize

            if reverse_lookup then
              err = _getnameinfo(sockaddr_p, sockaddr.bytesize,
                                 node, Socket::Constants::NI_MAXHOST, nil, 0, 0)

              name_info[2] = node.read_string if err == 0
            end

            err = _getnameinfo(sockaddr_p, sockaddr.bytesize,
                               node, Socket::Constants::NI_MAXHOST,
                               service, Socket::Constants::NI_MAXSERV,
                               flags)

            unless err == 0 then
              raise SocketError, gai_strerror(err)
            end

            sa_family = SockAddr_In.new(sockaddr)[:sin_family]

            name_info[0] = Socket::Constants::AF_TO_FAMILY[sa_family]
            name_info[1] = service.read_string
            name_info[3] = node.read_string
          end
        end
      end

      name_info[2] = name_info[3] if name_info[2].nil?
      name_info
    end

    def self.getpeername(descriptor)
      Rubinius::FFI::MemoryPointer.new :char, 128 do |sockaddr_storage_p|
        Rubinius::FFI::MemoryPointer.new :socklen_t do |len_p|
          len_p.write_int 128

          err = _getpeername descriptor, sockaddr_storage_p, len_p

          Errno.handle 'getpeername(2)' unless err == 0

          sockaddr_storage_p.read_string len_p.read_int
        end
      end
    end

    def self.getsockname(descriptor)
      Rubinius::FFI::MemoryPointer.new :char, 128 do |sockaddr_storage_p|
        Rubinius::FFI::MemoryPointer.new :socklen_t do |len_p|
          len_p.write_int 128

          err = _getsockname descriptor, sockaddr_storage_p, len_p

          Errno.handle 'getsockname(2)' unless err == 0

          sockaddr_storage_p.read_string len_p.read_int
        end
      end
    end

    def self.pack_sockaddr_in(host, port, family, type, flags)
      hints = Addrinfo.new
      hints[:ai_family] = family
      hints[:ai_socktype] = type
      hints[:ai_flags] = flags

      if host && host.empty?
        host = "0.0.0.0"
      end

      res_p = Rubinius::FFI::MemoryPointer.new :pointer

      err = _getaddrinfo host, port.to_s, hints.pointer, res_p

      raise SocketError, gai_strerror(err) unless err == 0

      return [] if res_p.read_pointer.null?

      res = Addrinfo.new res_p.read_pointer

      return res[:ai_addr].read_string(res[:ai_addrlen])

    ensure
      hints.free if hints

      if res_p then
        ptr = res_p.read_pointer

        freeaddrinfo ptr if ptr and not ptr.null?

        res_p.free
      end
    end

    def self.unpack_sockaddr_in(sockaddr, reverse_lookup)
      family, port, host, ip = getnameinfo sockaddr, Socket::Constants::NI_NUMERICHOST | Socket::Constants::NI_NUMERICSERV, reverse_lookup
      # On some systems this doesn't fail for families other than AF_INET(6)
      # so we raise manually here.
      raise ArgumentError, 'not an AF_INET/AF_INET6 sockaddr' unless family =~ /AF_INET/
      return host, ip, port.to_i
    end
  end

  module ListenAndAccept
    include IO::Socketable

    def listen(backlog)
      backlog = Rubinius::Type.coerce_to backlog, Fixnum, :to_int

      err = Socket::Foreign.listen descriptor, backlog

      Errno.handle 'listen(2)' unless err == 0

      err
    end

    def accept
      return if closed?

      fd = super

      socket = self.class.superclass.allocate
      IO.setup socket, fd, nil, true
      socket.binmode
      socket
    end

    #
    # Set nonblocking and accept.
    #
    def accept_nonblock
      return if closed?

      fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)

      fd = nil
      sockaddr = nil

      Rubinius::FFI::MemoryPointer.new 1024 do |sockaddr_p| # HACK from MRI
        Rubinius::FFI::MemoryPointer.new :int do |size_p|
          fd = Socket::Foreign.accept descriptor, sockaddr_p, size_p
        end
      end

      Errno.handle 'accept(2)' if fd < 0

      # TCPServer -> TCPSocket etc. *sigh*
      socket = self.class.superclass.allocate
      IO.setup socket, fd, nil, true
      socket
    end

  end

  include Socket::ListenAndAccept

  class SockAddr_In < Rubinius::FFI::Struct
    config("rbx.platform.sockaddr_in", :sin_family, :sin_port, :sin_addr, :sin_zero)

    def initialize(sockaddrin)
      @p = Rubinius::FFI::MemoryPointer.new sockaddrin.bytesize
      @p.write_string(sockaddrin, sockaddrin.bytesize)
      super(@p)
    end

    def to_s
      @p.read_string(@p.total)
    end

  end

  class SockAddr_In6 < Rubinius::FFI::Struct
    config(
      "rbx.platform.sockaddr_in6",
      :sin6_family, :sin6_port, :sin6_flowinfo, :sin6_addr, :sin6_scope_id
    )
  end

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
      linger = Socket::Foreign::Linger.new

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

      linger = Socket::Foreign::Linger.new
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
    class SockAddr_Un < Rubinius::FFI::Struct
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
    struct = Foreign::Ifaddrs.new
    status = Foreign.getifaddrs(struct)
    addrs  = []

    if status == -1
      raise "System call to getifaddrs() returned #{status.inspect}"
    end

    pointer = struct

    while pointer[:ifa_next]
      if pointer[:ifa_addr]
        addr   = Foreign::Sockaddr.new(pointer[:ifa_addr])
        family = addr[:sa_family]

        if family == AF_INET or family == AF_INET6
          size = family == AF_INET6 ? SockAddr_In6.size : SockAddr_In.size
          host = Rubinius::FFI::MemoryPointer.new(:char, Constants::NI_MAXHOST)

          status = Foreign._getnameinfo(addr,
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

      pointer = Foreign::Ifaddrs.new(pointer[:ifa_next])
    end

    Foreign.freeifaddrs(struct)

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
    addrinfos = Socket::Foreign.getaddrinfo(host, service, family, socktype,
                                            protocol, flags)

    addrinfos.map do |ai|
      addrinfo = []
      addrinfo << Socket::Constants::AF_TO_FAMILY[ai[1]]

      sockaddr = Foreign.unpack_sockaddr_in ai[4], !BasicSocket.do_not_reverse_lookup

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
      sockaddr = Socket::Foreign.pack_sockaddr_in(host, port, family, Socket::SOCK_DGRAM, 0)
    end

    family, port, host, ip = Socket::Foreign.getnameinfo(sockaddr, flags)
    [host, port]
  end

  def self.gethostname
    Rubinius::FFI::MemoryPointer.new :char, 1024 do |mp|  #magic number 1024 comes from MRI
      Socket::Foreign.gethostname(mp, 1024) # same here
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
        fn = Socket::Foreign.getservbyname(svc, prot)

        raise SocketError, "no such service #{service}/#{proto}" if fn.nil?

        s = Servent.new(fn.read_string(Servent.size))
        return Socket::Foreign.ntohs(s[:s_port])
      end
    end
  end

  def self.pack_sockaddr_in(port, host, type = Socket::SOCK_DGRAM, flags = 0)
    Socket::Foreign.pack_sockaddr_in host, port, Socket::AF_UNSPEC, type, flags
  end

  def self.unpack_sockaddr_in(sockaddr)
    host, address, port = Socket::Foreign.unpack_sockaddr_in sockaddr, false

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
      Socket::Foreign.socketpair(domain, type, protocol, mp)
      fd0, fd1 = mp.read_array_of_int(2)

      [ klass.from_descriptor(fd0), klass.from_descriptor(fd1) ]
    end
  end

  class << self
    alias_method :sockaddr_in, :pack_sockaddr_in
    alias_method :pair, :socketpair
  end

  # Only define these methods if we support unix sockets
  if self.const_defined?(:SockAddr_Un)
    def self.pack_sockaddr_un(file)
      SockAddr_Un.new(file).to_s
    end

    def self.unpack_sockaddr_un(addr)

      if addr.bytesize > Rubinius::FFI.config("sockaddr_un.sizeof")
        raise TypeError, "too long sockaddr_un - #{addr.bytesize} longer than #{Rubinius::FFI.config("sockaddr_un.sizeof")}"
      end

      struct = SockAddr_Un.new
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
    descriptor  = Socket::Foreign.socket family, socket_type, protocol

    Errno.handle 'socket(2)' if descriptor < 0

    IO.setup self, descriptor, nil, true
  end

  def bind(server_sockaddr)
    err = Socket::Foreign.bind(descriptor, server_sockaddr)
    Errno.handle 'bind(2)' unless err == 0
    err
  end

  def connect(sockaddr, extra=nil)
    if extra
      sockaddr = Socket.pack_sockaddr_in sockaddr, extra
    else
      sockaddr = StringValue(sockaddr)
    end

    status = Socket::Foreign.connect descriptor, sockaddr

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

    status = Socket::Foreign.connect descriptor, StringValue(sockaddr)
    if status < 0
      Errno.handle "connect(2)"
    end

    return status
  end
end
