$:.unshift(File.expand_path('..', __FILE__))

require 'custom/helpers/each_ip_protocol'

class MSpecScript
  if RUBY_ENGINE == 'rbx'
    MSpec.enable_feature :pure_ruby_addrinfo
  end

  set :backtrace_filter, %r{(bin/mspec|lib/mspec|kernel)}
end

# vim: set ft=ruby:
