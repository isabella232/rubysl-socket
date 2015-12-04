module RubySL
  module Socket
    module Foreign
      class Hostent < Rubinius::FFI::Struct
        config('rbx.platform.hostent', :h_name, :h_aliases, :h_addrtype,
               :h_length, :h_addr_list)
      end
    end
  end
end
