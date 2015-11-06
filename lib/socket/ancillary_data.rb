class Socket < BasicSocket
  class AncillaryData
    attr_reader :family, :level, :type, :data

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
  end
end