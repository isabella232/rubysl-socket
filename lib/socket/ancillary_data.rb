class Socket < BasicSocket
  class AncillaryData
    attr_reader :family, :level, :type, :data

    def self.int(family, level, type, integer)
      new(family, level, type, [integer].pack('I'))
    end

    def self.unix_rights(*ios)
      descriptors = ios.map do |io|
        unless io.is_a?(IO)
          raise TypeError, "IO expected, got #{io.class} instead"
        end

        io.fileno
      end

      instance = new(:UNIX, :SOCKET, :RIGHTS, descriptors.pack('I*'))

      # MRI sets this using a hidden instance variable ("unix_rights"). Because
      # you can't set hidden instance variables from within Ruby we'll just
      # prefix the variable with an underscore. Lets hope people don't mess with
      # it.
      instance.instance_variable_set(:@_unix_rights, ios)

      instance
    end

    def initialize(family, level, type, data)
      @family = RubySL::Socket::Helpers.address_family(family)
      @data   = RubySL::Socket::Helpers.coerce_to_string(data)
      @level  = RubySL::Socket::AncillaryData.level(level)
      @type   = RubySL::Socket::AncillaryData.type(@family, @level, type)
    end

    def cmsg_is?(level, type)
      level = RubySL::Socket::AncillaryData.level(level)
      type  = RubySL::Socket::AncillaryData.type(@family, level, type)

      @level == level && @type == type
    end

    def int
      unpacked = @data.unpack('I')[0]

      unless unpacked
        raise TypeError, 'data could not be unpacked into a Fixnum'
      end

      unpacked
    end

    def unix_rights
      if @level != Socket::SOL_SOCKET or @type != Socket::SCM_RIGHTS
        raise TypeError, 'SCM_RIGHTS ancillary data expected'
      end

      @_unix_rights
    end
  end
end
