require 'socket'

describe 'Addrinfo.foreach' do
  it 'yields Addrinfo instances  to the supplied block' do
    yielded = []

    Addrinfo.foreach('localhost', 80) do |addr|
      addr.should be_an_instance_of(Addrinfo)

      yielded << addr
    end

    # To check if the block is actually called.
    yielded.empty?.should == false
  end
end
