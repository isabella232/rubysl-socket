module RubySL
  module Socket
    module IPv6
      # The IPv6 loopback address as produced by inet_pton(INET6, "::1")
      LOOPBACK = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]

      # The first 10 bytes of an IPv4 compatible IPv6 address.
      COMPAT_PREFIX = [0] * 10

      # All possible byte pairs following the compatibility prefix.
      COMPAT_PREFIX_FOLLOW = [ [0, 0], [255, 255] ]

      def self.ipv4_compatible?(bytes)
        prefix = bytes.first(10)
        follow = bytes[10..11]

        prefix == COMPAT_PREFIX &&
          COMPAT_PREFIX_FOLLOW.include?(follow) &&
          (bytes[-4] > 0 || bytes[-3] > 0 || bytes[-2] > 0)
      end
    end
  end
end
