module RubySL
  module Socket
    module Listen
      def self.listen(source, backlog)
        backlog = Rubinius::Type.coerce_to(backlog, Fixnum, :to_int)
        err     = Foreign.listen(source.descriptor, backlog)

        Errno.handle('listen(2)') if err < 0

        0
      end
    end
  end
end
