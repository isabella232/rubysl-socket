class MSpecScript
  if RUBY_ENGINE == 'rbx'
    MSpec.enable_feature :pure_ruby_addrinfo
  end

  set :backtrace_filter, %r{(bin/mspec|lib/mspec|kernel)}
end

# vim: set ft=ruby:
