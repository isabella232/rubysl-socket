require 'fcntl'
require 'resolv'

require 'rubysl/socket'
require 'rubysl/socket/version'
require 'rubysl/socket/helpers'
require 'rubysl/socket/socket_options'
require 'rubysl/socket/listen_and_accept'

require 'rubysl/socket/bsd' if RubySL::Socket.bsd_support?
require 'rubysl/socket/linux' if Rubinius.linux?

require 'socket/socket_error'
require 'socket/basic_socket'
require 'socket/constants'

require 'rubysl/socket/foreign/addrinfo'
require 'rubysl/socket/foreign/linger'
require 'rubysl/socket/foreign/ifaddrs'
require 'rubysl/socket/foreign/sockaddr'
require 'rubysl/socket/foreign/sockaddr_in'
require 'rubysl/socket/foreign/sockaddr_in6'
require 'rubysl/socket/foreign/sockaddr_un'

require 'rubysl/socket/foreign'
require 'socket/socket'
require 'socket/option'
require 'socket/mri'
require 'socket/unix_socket'
require 'socket/unix_server'
require 'socket/ip_socket'
require 'socket/udp_socket'
require 'socket/tcp_socket'
require 'socket/tcp_server'
require 'socket/addrinfo'
