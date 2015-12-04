require 'socket'

describe 'TCPServer#listen' do
  before do
    @server = TCPServer.new('127.0.0.1', 0)
  end

  after do
    @server.close
  end

  it 'returns 0' do
    @server.listen(1).should == 0
  end

  it "raises when the given argument can't be coerced to a Fixnum" do
    proc { @server.listen('cats') }.should raise_error(TypeError)
  end
end
