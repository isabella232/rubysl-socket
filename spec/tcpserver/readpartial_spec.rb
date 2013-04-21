require File.expand_path('../../fixtures/classes', __FILE__)

describe "TCPServer#readpartial" do
  after(:each) do
    @server.close if @server
    @socket.close if @socket
  end
end
