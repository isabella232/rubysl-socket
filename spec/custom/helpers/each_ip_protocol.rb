class Object
  def each_ip_protocol
    describe 'using IPv4' do
      yield Socket::AF_INET, '127.0.0.1'
    end

    describe 'using IPv6' do
      yield Socket::AF_INET6, '::1'
    end
  end
end
