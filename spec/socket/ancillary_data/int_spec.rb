require 'socket'

describe 'Socket::AncillaryData.int' do
  before do
    @data = Socket::AncillaryData.int(:INET, :SOCKET, :RIGHTS, 4)
  end

  it 'returns a Socket::AncillaryData' do
    @data.should be_an_instance_of(Socket::AncillaryData)
  end

  it 'sets the family' do
    @data.family.should == Socket::AF_INET
  end

  it 'sets the level' do
    @data.level.should == Socket::SOL_SOCKET
  end

  it 'sets the type' do
    @data.type.should == Socket::SCM_RIGHTS
  end

  it 'sets the data to a packed String' do
    @data.data.should == [4].pack('I')
  end
end

describe 'Socket::AncillaryData#int' do
  it 'returns the data as a Fixnum' do
    data = Socket::AncillaryData.int(:UNIX, :SOCKET, :RIGHTS, 4)

    data.int.should == 4
  end

  it 'raises when the data is not a Fixnum' do
    data = Socket::AncillaryData.new(:UNIX, :SOCKET, :RIGHTS, 'ugh')

    proc { data.int }.should raise_error(TypeError)
  end
end