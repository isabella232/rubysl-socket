module RubySL
  module Socket
    def self.bsd_support?
      Rubinius.bsd? || Rubinius.darwin?
    end
  end
end
