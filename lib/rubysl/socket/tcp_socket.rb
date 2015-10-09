class TCPSocket < IPSocket
  FFI = Rubinius::FFI

  def self.gethostbyname(hostname)
    addrinfos = Socket.getaddrinfo(hostname, nil)

    hostname     = addrinfos.first[2]
    family       = addrinfos.first[4]
    addresses    = []
    alternatives = []
    addrinfos.each do |a|
      alternatives << a[2] unless a[2] == hostname
      addresses    << a[3] if a[4] == family
    end

    [hostname, alternatives.uniq, family] + addresses.uniq
  end

  #
  # @todo   Is it correct to ignore the to? If not, does
  #         the socket need to be reconnected? --rue
  #
  def send(bytes_to_read, flags, to = nil)
    super(bytes_to_read, flags)
  end


  def initialize(host, port, local_host=nil, local_service=nil)
    @no_reverse_lookup = self.class.do_not_reverse_lookup
    @host = host
    @port = port

    tcp_setup @host, @port, local_host, local_service
  end

  def tcp_setup(remote_host, remote_service, local_host = nil,
                local_service = nil, server = false)
    status = nil
    syscall = nil
    remote_host    = StringValue(remote_host)    if remote_host
    if remote_service
      if remote_service.kind_of? Fixnum
        remote_service = remote_service.to_s
      else
        remote_service = StringValue(remote_service)
      end
    end

    flags = server ? Socket::AI_PASSIVE : 0
    @remote_addrinfo = Socket::Foreign.getaddrinfo(remote_host,
                                                   remote_service,
                                                   Socket::AF_UNSPEC,
                                                   Socket::SOCK_STREAM, 0,
                                                   flags)

    if server == false and (local_host or local_service)
      local_host    = local_host.to_s    if local_host
      local_service = local_service.to_s if local_service
      @local_addrinfo = Socket::Foreign.getaddrinfo(local_host,
                                                    local_service,
                                                    Socket::AF_UNSPEC,
                                                    Socket::SOCK_STREAM, 0, 0)
    end

    sock = nil

    @remote_addrinfo.each do |addrinfo|
      flags, family, socket_type, protocol, sockaddr, canonname = addrinfo

      sock = Socket::Foreign.socket family, socket_type, protocol
      syscall = 'socket(2)'

      next if sock < 0

      if server
        FFI::MemoryPointer.new :socklen_t do |val|
          val.write_int 1
          level = Socket::Constants::SOL_SOCKET
          optname = Socket::Constants::SO_REUSEADDR
          error = Socket::Foreign.setsockopt(sock, level,
                                             optname, val,
                                             val.total)
          # Don't check error because if this fails, we just continue
          # anyway.
        end

        status = Socket::Foreign.bind sock, sockaddr
        syscall = 'bind(2)'
      else
        if @local_addrinfo
          # Pick a local_addrinfo for the family and type of
          # the remote side
          li = @local_addrinfo.find do |i|
            i[1] == family && i[2] == socket_type
          end

          if li
            status = Socket::Foreign.bind sock, li[4]
            syscall = 'bind(2)'
          else
            status = 1
          end
        else
          status = 1
        end

        if status >= 0
          status = Socket::Foreign.connect sock, sockaddr
          syscall = 'connect(2)'
        end
      end

      if status < 0
        Socket::Foreign.close sock
      else
        break
      end
    end

    if status < 0
      Errno.handle syscall
    end

    if server
      err = Socket::Foreign.listen sock, 5
      unless err == 0
        Socket::Foreign.close sock
        Errno.handle syscall
      end
    end

    # Only setup once we have found a socket we can use. Otherwise
    # because we manually close a socket fd, we can create an IO fd
    # alias condition which causes EBADF because when an IO is finalized
    # and it's fd has been closed underneith it, we close someone elses
    # fd!
    IO.setup self, sock, nil, true
  end
  private :tcp_setup

  def from_descriptor(descriptor)
    IO.setup self, descriptor, nil, true

    self
  end
end
