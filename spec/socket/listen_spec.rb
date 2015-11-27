require 'socket'

describe 'Socket#listen' do
  describe 'using a DGRAM socket' do
    before do
      @server = Socket.new(:INET, :DGRAM)
      @client = Socket.new(:INET, :DGRAM)

      @server.bind(Socket.sockaddr_in(0, '127.0.0.1'))
    end

    it 'raises Errno::EOPNOTSUPP' do
      proc { @server.listen(1) }.should raise_error(Errno::EOPNOTSUPP)
    end
  end

  describe 'using a STREAM socket' do
    before do
      @server = Socket.new(:INET, :STREAM)
      @client = Socket.new(:INET, :STREAM)

      @server.bind(Socket.sockaddr_in(0, '127.0.0.1'))
    end

    it 'returns 0' do
      @server.listen(1).should == 0
    end

    it "raises when the given argument can't be coerced to a Fixnum" do
      proc { @server.listen('cats') }.should raise_error(TypeError)
    end
  end
end
