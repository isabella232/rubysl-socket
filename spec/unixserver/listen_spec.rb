require 'socket'

describe 'UNIXServer#listen' do
  before do
    @path   = tmp('unix_socket')
    @server = UNIXServer.new(@path)
  end

  after do
    @server.close

    rm_r(@path)
  end

  it 'returns 0' do
    @server.listen(1).should == 0
  end
end
