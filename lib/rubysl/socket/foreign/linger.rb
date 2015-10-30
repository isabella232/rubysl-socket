module RubySL
  module Socket
    module Foreign
      class Linger < Rubinius::FFI::Struct
        config("rbx.platform.linger", :l_onoff, :l_linger)
      end
    end
  end
end
