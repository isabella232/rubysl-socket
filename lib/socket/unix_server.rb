class UNIXServer < UNIXSocket
  def initialize(path)
    @no_reverse_lookup = self.class.do_not_reverse_lookup
    @path = path
    unix_setup(true)
  end

  def listen(backlog)
    RubySL::Socket.listen(self, backlog)
  end

  def accept
    RubySL::Socket.accept(self, UNIXSocket)
  end

  def accept_nonblock
    RubySL::Socket.accept_nonblock(self, UNIXSocket)
  end
end
