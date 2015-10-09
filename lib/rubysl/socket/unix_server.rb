class UNIXServer < UNIXSocket
  include Socket::ListenAndAccept

  def initialize(path)
    @no_reverse_lookup = self.class.do_not_reverse_lookup
    @path = path
    unix_setup(true)
  end
end
