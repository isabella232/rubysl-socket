class IPSocket < BasicSocket
  undef_method :getpeereid

  def self.getaddress(host)
    RubySL::Socket::Foreign.getaddress(host)
  end

  def addr(reverse_lookup = nil)
    RubySL::Socket::Helpers.address_info(:getsockname, self, reverse_lookup)
  end

  def peeraddr(reverse_lookup=nil)
    RubySL::Socket::Helpers.address_info(:getpeername, self, reverse_lookup)
  end

  def recvfrom(maxlen, flags = 0)
    flags = 0 if flags.nil?

    socket_recv(maxlen, flags, 1)
  end
end
