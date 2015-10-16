require File.expand_path('../../shared/recv_nonblock', __FILE__)
require File.expand_path('../../fixtures/classes', __FILE__)

describe "BasicSocket#recv_nonblock" do
  it_behaves_like :socket_recv_nonblock, :recv_nonblock
end
