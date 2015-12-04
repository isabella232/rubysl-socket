module RubySL
  module Socket
    def self.bsd_support?
      Rubinius.bsd? || Rubinius.darwin?
    end

    def self.aliases_for_hostname(hostname)
      pointer  = Foreign.gethostbyname(hostname)
      struct   = Foreign::Hostent.new(pointer)
      pointers = struct[:h_aliases].get_array_of_pointer(0, struct[:h_length])

      pointers.map { |p| p.read_string }
    end
  end
end
