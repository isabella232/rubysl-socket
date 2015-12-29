$:.unshift(File.expand_path('..', __FILE__))

require 'socket'
require 'custom/helpers/each_ip_protocol'

# This ensures we can actually read backtraces Travis CI might spit out.
if ENV['TRAVIS'] and RUBY_ENGINE == 'rbx'
  Rubinius::TERMINAL_WIDTH = 120
end

class MSpecScript
  if RUBY_ENGINE == 'rbx'
    MSpec.enable_feature :pure_ruby_addrinfo
  end

  if ::Socket.const_defined?(:SOCK_PACKET)
    MSpec.enable_feature :sock_packet
  end

  if ::Socket.const_defined?(:AF_UNIX)
    MSpec.enable_feature :unix_socket
  end

  if ::Socket.const_defined?(:UDP_CORK)
    MSpec.enable_feature :udp_cork
  end

  set :backtrace_filter, %r{(bin/mspec|lib/mspec|kernel)}
end

# vim: set ft=ruby:
