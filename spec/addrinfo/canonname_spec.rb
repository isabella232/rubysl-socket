require 'socket'

describe 'Addrinfo#canonname' do
  describe 'when the canonical name is available' do
    it 'returns the canonical name' do
      # TODO: figure out how we're going to set the canonical name
    end
  end

  describe 'when the canonical name is not available' do
    before do
      @addr = Addrinfo.new('127.0.0.1', 9999)
    end

    it 'returns nil' do
      @addr.canonname.should be_nil
    end
  end
end
