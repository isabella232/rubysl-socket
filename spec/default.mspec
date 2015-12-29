$:.unshift(File.expand_path('..', __FILE__))

require 'socket'
require 'custom/helpers/each_ip_protocol'

class MSpecScript
  if RUBY_ENGINE == 'rbx'
    MSpec.enable_feature :pure_ruby_addrinfo
  end

  if ::Socket.const_defined?(:SOCK_PACKET)
    MSpec.enable_feature :sock_packet
  end

  set :backtrace_filter, %r{(bin/mspec|lib/mspec|kernel)}
end

# vim: set ft=ruby:
