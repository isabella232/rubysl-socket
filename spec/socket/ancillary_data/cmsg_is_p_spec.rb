require 'socket'

describe 'Socket::AncillaryData#cmsg_is?' do
  describe 'using :INET, :IPV6, :PKTINFO as the family, level, and type' do
    before do
      @data = Socket::AncillaryData.new(:INET, :IPV6, :PKTINFO, '')
    end

    it 'returns true when comparing with IPPROTO_IPV6 and IPV6_PKTINFO' do
      @data.cmsg_is?(Socket::IPPROTO_IPV6, Socket::IPV6_PKTINFO).should == true
    end

    it 'returns true when comparing with :IPV6 and :PKTINFO' do
      @data.cmsg_is?(:IPV6, :PKTINFO).should == true
    end

    it 'returns false when comparing with :IP and :PKTINFO' do
      @data.cmsg_is?(:IP, :PKTINFO).should == false
    end

    it 'returns false when comparing with :IPV6 and :NEXTHOP' do
      @data.cmsg_is?(:IPV6, :NEXTHOP).should == false
    end

    it 'returns false when comparing with :SOCKET and :RIGHTS' do
      @data.cmsg_is?(:SOCKET, :RIGHTS).should == false
    end

    it 'raises SocketError when comparign with :IPV6 and :RIGHTS' do
      proc { @data.cmsg_is?(:IPV6, :RIGHTS) }.should raise_error(SocketError)
    end
  end
end
