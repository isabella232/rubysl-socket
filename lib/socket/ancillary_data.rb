class Socket < BasicSocket
  class AncillaryData
    LEVEL_PREFIXES = {
      Socket::SOL_SOCKET   => %w{SCM_ UNIX},
      Socket::IPPROTO_IP   => %w{IP_ IP},
      Socket::IPPROTO_IPV6 => %w{IPV6_ IPV6},
      Socket::IPPROTO_TCP  => %w{TCP_ TCP},
      Socket::IPPROTO_UDP  => %w{UDP_ UDP}
    }

    attr_reader :family, :level, :type, :data

    def initialize(family, level, type, data)
      @family = RubySL::Socket::Helpers.address_family(family)
      @data   = RubySL::Socket::Helpers.coerce_to_string(data)

      if level.is_a?(Fixnum)
        @level = level
      else
        level = RubySL::Socket::Helpers.coerce_to_string(level)

        if level == 'SOL_SOCKET' or level == 'SOCKET'
          @level = Socket::SOL_SOCKET

        # Translates "TCP" into "IPPROTO_TCP", "UDP" into "IPPROTO_UDP", etc.
        else
          @level = RubySL::Socket::Helpers.prefixed_socket_constant(level, 'IPPROTO_') do
            "unknown protocol level: #{level}"
          end
        end
      end

      if type.is_a?(Fixnum)
        @type = type
      else
        type = RubySL::Socket::Helpers.coerce_to_string(type)

        if @family == Socket::AF_INET or @family == Socket::AF_INET6
          prefix, label = LEVEL_PREFIXES[@level]
        else
          prefix, label = LEVEL_PREFIXES[Socket::SOL_SOCKET]
        end

        # Translates "RIGHTS" into "SCM_RIGHTS", "CORK" into "TCP_CORK" (when
        # the level is IPPROTO_TCP), etc.
        if prefix and label
          @type = RubySL::Socket::Helpers.prefixed_socket_constant(type, prefix) do
            "Unknown #{label} control message: #{type}"
          end
        else
          raise TypeError, "no implicit conversion of #{type.class} into Integer"
        end
      end
    end
  end
end
