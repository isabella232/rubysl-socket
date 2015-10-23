class BasicSocket < IO
  class << self
    def from_descriptor(fixnum)
      sock = allocate()
      sock.from_descriptor(fixnum)
      return sock
    end

    alias :for_fd :from_descriptor
  end

  def from_descriptor(fixnum)
    IO.setup self, fixnum, nil, true
    return self
  end

  def self.do_not_reverse_lookup=(setting)
    @no_reverse_lookup = setting
  end

  def self.do_not_reverse_lookup
    @no_reverse_lookup = true unless defined? @no_reverse_lookup
    @no_reverse_lookup
  end

  def do_not_reverse_lookup=(setting)
    @no_reverse_lookup = setting
  end

  def do_not_reverse_lookup
    @no_reverse_lookup
  end

  def getsockopt(level, optname)
    data = RubySL::Socket::Foreign.getsockopt(descriptor, level, optname)

    sockaddr = RubySL::Socket::Foreign.getsockname(descriptor)

    family, _ = RubySL::Socket::Foreign.getnameinfo(
      sockaddr,
      Socket::Constants::NI_NUMERICHOST | Socket::Constants::NI_NUMERICSERV
    )

    Socket::Option.new(family, level, optname, data)
  end

  def setsockopt(level_or_option, optname=nil, optval=nil)
    level = nil

    case level_or_option
    when Socket::Option
      if !optname.nil?
        raise ArgumentError, "given 2, expected 3"
      end
      level = level_or_option.level
      optname = level_or_option.optname
      optval = level_or_option.data
    else
      if level_or_option.nil? or optname.nil?
        nb_arg = 3 - [level_or_option, optname, optval].count(nil)
        raise ArgumentError, "given #{nb_arg}, expected 3"
      end
      level = level_or_option
    end

    optval = 1 if optval == true
    optval = 0 if optval == false

    error = 0

    sockname = RubySL::Socket::Foreign.getsockname descriptor
    family = RubySL::Socket::Foreign.getnameinfo(sockname).first

    level = level_arg(family, level)
    optname = optname_arg(level, optname)

    case optval
    when Fixnum then
      Rubinius::FFI::MemoryPointer.new :socklen_t do |val|
        val.write_int optval
        error = RubySL::Socket::Foreign.setsockopt(descriptor, level,
                                           optname, val,
                                           val.total)
      end
    when String then
      Rubinius::FFI::MemoryPointer.new optval.bytesize do |val|
        val.write_string optval, optval.bytesize
        error = RubySL::Socket::Foreign.setsockopt(descriptor, level,
                                           optname, val,
                                           optval.size)
      end
    else
      raise TypeError, "socket option should be a String, a Fixnum, true, or false"
    end

    Errno.handle "Unable to set socket option" unless error == 0

    return 0
  end

  def getsockname()
    return RubySL::Socket::Foreign.getsockname(descriptor)
  end

  #
  # Obtain peername information for this socket.
  #
  # @see  Socket.getpeername
  #
  def getpeername()
    RubySL::Socket::Foreign.getpeername @descriptor
  end

  #
  #
  #
  def send(message, flags, to = nil)
    connect to if to

    bytes = message.bytesize
    bytes_sent = 0

    Rubinius::FFI::MemoryPointer.new :char, bytes + 1 do |buffer|
      buffer.write_string message, bytes
      bytes_sent = RubySL::Socket::Foreign.send(descriptor, buffer, bytes, flags)
      Errno.handle 'send(2)' if bytes_sent < 0
    end

    bytes_sent
  end

  def recvfrom(bytes_to_read, flags = 0)
    bytes = socket_recv(bytes_to_read, flags, 0)
    addr  = Addrinfo.new(['AF_UNSPEC'], Socket::PF_UNSPEC, Socket::SOCK_STREAM)

    return bytes, addr
  end

  def recv(bytes_to_read, flags = 0)
    # FIXME 0 is knowledge from io.cpp
    return socket_recv(bytes_to_read, flags, 0)
  end

  def close_read
    ensure_open

    # If we were only in readonly mode, close it all together
    if @mode & ACCMODE == RDONLY
      return close
    end

    # MRI doesn't check if shutdown worked, so we don't.
    RubySL::Socket::Foreign.shutdown @descriptor, 0

    @mode = WRONLY

    nil
  end

  def close_write
    ensure_open

    # If we were only in writeonly mode, close it all together
    if @mode & ACCMODE == WRONLY
      return close
    end

    RubySL::Socket::Foreign.shutdown @descriptor, 1

    # Mark it as read only
    @mode = RDONLY

    nil
  end

  def recv_nonblock(bytes_to_read, flags = 0)
    fcntl Fcntl::F_SETFL, Fcntl::O_NONBLOCK
    socket_recv bytes_to_read, flags, 0
  rescue Errno::EWOULDBLOCK
    raise Errno::EAGAIN
  end

  def shutdown(how = 2)
    err = RubySL::Socket::Foreign.shutdown @descriptor, how
    Errno.handle "shutdown" unless err == 0
  end

  # MRI defines this method in BasicSocket and stuffs all logic in it. Since
  # inheriting classes behave differently we overwrite this method in said
  # classes. The method here exists so that code such as the following still
  # works: BasicSocket.method_defined?(:local_address).
  def local_address
    raise NotImplementedError,
      'This method must be implemented by classes inheriting from BasicSocket'
  end

  def remote_address
    raise NotImplementedError,
      'This method must be implemented by classes inheriting from BasicSocket'
  end

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
    else
      level
    end
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
  end

  def is_ip_family?(family)
    family == "AF_INET" || family == "AF_INET6"
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
    if Socket::Constants.const_defined?("#{prefix}_#{suffix}")
      Socket::Constants.const_get("#{prefix}_#{suffix}")
    end
  end
end
