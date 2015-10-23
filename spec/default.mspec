class MSpecScript
  if RUBY_ENGINE == 'rbx'
    MSpec.enable_feature :pure_ruby_addrinfo
  end
end

# vim: set ft=ruby:
