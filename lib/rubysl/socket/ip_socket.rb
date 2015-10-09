class IPSocket < BasicSocket
  def self.getaddress(host)
    Socket::Foreign.getaddress host
  end

  def addr(reverse_lookup=nil)
    sockaddr = Socket::Foreign.getsockname descriptor

    reverse_lookup = !do_not_reverse_lookup if reverse_lookup.nil?

    family, port, host, ip = Socket::Foreign.getnameinfo sockaddr, Socket::Constants::NI_NUMERICHOST | Socket::Constants::NI_NUMERICSERV, reverse_lookup
    [family, port.to_i, host, ip]
  end

  def peeraddr(reverse_lookup=nil)
    sockaddr = Socket::Foreign.getpeername descriptor

    reverse_lookup = !do_not_reverse_lookup if reverse_lookup.nil?

    family, port, host, ip = Socket::Foreign.getnameinfo sockaddr, Socket::Constants::NI_NUMERICHOST | Socket::Constants::NI_NUMERICSERV, reverse_lookup
    [family, port.to_i, host, ip]
  end

  def recvfrom(maxlen, flags = 0)
    # FIXME 1 is hardcoded knowledge from io.cpp
    flags = 0 if flags.nil?
    socket_recv maxlen, flags, 1
  end

  def recvfrom_nonblock(maxlen, flags = 0)
    # Set socket to non-blocking, if we can
    # Todo: Ensure this works in Windows!  If not, I claim that's Fcntl's fault.
    fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
    flags = 0 if flags.nil?
    flags |= Socket::MSG_DONTWAIT

    IO.select([self])
    return recvfrom(maxlen, flags)
  end
end
