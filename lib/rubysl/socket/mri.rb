# Everything below is copied from the MRI codebase. The Ruby license is
# attached below.
#
# Ruby is copyrighted free software by Yukihiro Matsumoto <matz@netlab.jp>.
# You can redistribute it and/or modify it under either the terms of the
# 2-clause BSDL (see the file BSDL), or the conditions below:
#
#   1. You may make and give away verbatim copies of the source form of the
#      software without restriction, provided that you duplicate all of the
#      original copyright notices and associated disclaimers.
#
#   2. You may modify your copy of the software in any way, provided that
#      you do at least ONE of the following:
#
#        a) place your modifications in the Public Domain or otherwise
#           make them Freely Available, such as by posting said
# 	  modifications to Usenet or an equivalent medium, or by allowing
# 	  the author to include your modifications in the software.
#
#        b) use the modified software only within your corporation or
#           organization.
#
#        c) give non-standard binaries non-standard names, with
#           instructions on where to get the original software distribution.
#
#        d) make other distribution arrangements with the author.
#
#   3. You may distribute the software in object code or binary form,
#      provided that you do at least ONE of the following:
#
#        a) distribute the binaries and library files of the software,
# 	  together with instructions (in the manual page or equivalent)
# 	  on where to get the original distribution.
#
#        b) accompany the distribution with the machine-readable source of
# 	  the software.
#
#        c) give non-standard binaries non-standard names, with
#           instructions on where to get the original software distribution.
#
#        d) make other distribution arrangements with the author.
#
#   4. You may modify and include the part of the software into any other
#      software (possibly commercial).  But some files in the distribution
#      are not written by the author, so that they are not under these terms.
#
#      For the list of those files and their copying conditions, see the
#      file LEGAL.
#
#   5. The scripts and library files supplied as input to or produced as
#      output from the software do not automatically fall under the
#      copyright of the software, but belong to whomever generated them,
#      and may be sold commercially, and may be aggregated with this
#      software.
#
#   6. THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#      IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#      PURPOSE.

class Addrinfo
  # creates an Addrinfo object from the arguments.
  #
  # The arguments are interpreted as similar to self.
  #
  #   Addrinfo.tcp("0.0.0.0", 4649).family_addrinfo("www.ruby-lang.org", 80)
  #   #=> #<Addrinfo: 221.186.184.68:80 TCP (www.ruby-lang.org:80)>
  #
  #   Addrinfo.unix("/tmp/sock").family_addrinfo("/tmp/sock2")
  #   #=> #<Addrinfo: /tmp/sock2 SOCK_STREAM>
  #
  def family_addrinfo(*args)
    if args.empty?
      raise ArgumentError, "no address specified"
    elsif Addrinfo === args.first
      raise ArgumentError, "too many arguments" if args.length != 1
      addrinfo = args.first
      if (self.pfamily != addrinfo.pfamily) ||
         (self.socktype != addrinfo.socktype)
        raise ArgumentError, "Addrinfo type mismatch"
      end
      addrinfo
    elsif self.ip?
      raise ArgumentError, "IP address needs host and port but #{args.length} arguments given" if args.length != 2
      host, port = args
      Addrinfo.getaddrinfo(host, port, self.pfamily, self.socktype, self.protocol)[0]
    elsif self.unix?
      raise ArgumentError, "UNIX socket needs single path argument but #{args.length} arguments given" if args.length != 1
      path, = args
      Addrinfo.unix(path)
    else
      raise ArgumentError, "unexpected family"
    end
  end

  # creates a new Socket connected to the address of +local_addrinfo+.
  #
  # If _local_addrinfo_ is nil, the address of the socket is not bound.
  #
  # The _timeout_ specify the seconds for timeout.
  # Errno::ETIMEDOUT is raised when timeout occur.
  #
  # If a block is given the created socket is yielded for each address.
  #
  def connect_internal(local_addrinfo, timeout=nil) # :yields: socket
    sock = Socket.new(self.pfamily, self.socktype, self.protocol)
    begin
      sock.ipv6only! if self.ipv6?
      sock.bind local_addrinfo if local_addrinfo
      if timeout
        begin
          sock.connect_nonblock(self)
        rescue IO::WaitWritable
          if !IO.select(nil, [sock], nil, timeout)
            raise Errno::ETIMEDOUT, 'user specified timeout'
          end
          begin
            sock.connect_nonblock(self) # check connection failure
          rescue Errno::EISCONN
          end
        end
      else
        sock.connect(self)
      end
    rescue Exception
      sock.close
      raise
    end
    if block_given?
      begin
        yield sock
      ensure
        sock.close if !sock.closed?
      end
    else
      sock
    end
  end
  private :connect_internal

  # :call-seq:
  #   addrinfo.connect_from([local_addr_args], [opts]) {|socket| ... }
  #   addrinfo.connect_from([local_addr_args], [opts])
  #
  # creates a socket connected to the address of self.
  #
  # If one or more arguments given as _local_addr_args_,
  # it is used as the local address of the socket.
  # _local_addr_args_ is given for family_addrinfo to obtain actual address.
  #
  # If _local_addr_args_ is not given, the local address of the socket is not bound.
  #
  # The optional last argument _opts_ is options represented by a hash.
  # _opts_ may have following options:
  #
  # [:timeout] specify the timeout in seconds.
  #
  # If a block is given, it is called with the socket and the value of the block is returned.
  # The socket is returned otherwise.
  #
  #   Addrinfo.tcp("www.ruby-lang.org", 80).connect_from("0.0.0.0", 4649) {|s|
  #     s.print "GET / HTTP/1.0\r\nHost: www.ruby-lang.org\r\n\r\n"
  #     puts s.read
  #   }
  #
  #   # Addrinfo object can be taken for the argument.
  #   Addrinfo.tcp("www.ruby-lang.org", 80).connect_from(Addrinfo.tcp("0.0.0.0", 4649)) {|s|
  #     s.print "GET / HTTP/1.0\r\nHost: www.ruby-lang.org\r\n\r\n"
  #     puts s.read
  #   }
  #
  def connect_from(*args, &block)
    opts = Hash === args.last ? args.pop : {}
    local_addr_args = args
    connect_internal(family_addrinfo(*local_addr_args), opts[:timeout], &block)
  end

  # :call-seq:
  #   addrinfo.connect([opts]) {|socket| ... }
  #   addrinfo.connect([opts])
  #
  # creates a socket connected to the address of self.
  #
  # The optional argument _opts_ is options represented by a hash.
  # _opts_ may have following options:
  #
  # [:timeout] specify the timeout in seconds.
  #
  # If a block is given, it is called with the socket and the value of the block is returned.
  # The socket is returned otherwise.
  #
  #   Addrinfo.tcp("www.ruby-lang.org", 80).connect {|s|
  #     s.print "GET / HTTP/1.0\r\nHost: www.ruby-lang.org\r\n\r\n"
  #     puts s.read
  #   }
  #
  def connect(opts={}, &block)
    connect_internal(nil, opts[:timeout], &block)
  end

  # :call-seq:
  #   addrinfo.connect_to([remote_addr_args], [opts]) {|socket| ... }
  #   addrinfo.connect_to([remote_addr_args], [opts])
  #
  # creates a socket connected to _remote_addr_args_ and bound to self.
  #
  # The optional last argument _opts_ is options represented by a hash.
  # _opts_ may have following options:
  #
  # [:timeout] specify the timeout in seconds.
  #
  # If a block is given, it is called with the socket and the value of the block is returned.
  # The socket is returned otherwise.
  #
  #   Addrinfo.tcp("0.0.0.0", 4649).connect_to("www.ruby-lang.org", 80) {|s|
  #     s.print "GET / HTTP/1.0\r\nHost: www.ruby-lang.org\r\n\r\n"
  #     puts s.read
  #   }
  #
  def connect_to(*args, &block)
    opts = Hash === args.last ? args.pop : {}
    remote_addr_args = args
    remote_addrinfo = family_addrinfo(*remote_addr_args)
    remote_addrinfo.send(:connect_internal, self, opts[:timeout], &block)
  end

  # creates a socket bound to self.
  #
  # If a block is given, it is called with the socket and the value of the block is returned.
  # The socket is returned otherwise.
  #
  #   Addrinfo.udp("0.0.0.0", 9981).bind {|s|
  #     s.local_address.connect {|s| s.send "hello", 0 }
  #     p s.recv(10) #=> "hello"
  #   }
  #
  def bind
    sock = Socket.new(self.pfamily, self.socktype, self.protocol)
    begin
      sock.ipv6only! if self.ipv6?
      sock.setsockopt(:SOCKET, :REUSEADDR, 1)
      sock.bind(self)
    rescue Exception
      sock.close
      raise
    end
    if block_given?
      begin
        yield sock
      ensure
        sock.close if !sock.closed?
      end
    else
      sock
    end
  end

  # creates a listening socket bound to self.
  def listen(backlog=Socket::SOMAXCONN)
    sock = Socket.new(self.pfamily, self.socktype, self.protocol)
    begin
      sock.ipv6only! if self.ipv6?
      sock.setsockopt(:SOCKET, :REUSEADDR, 1)
      sock.bind(self)
      sock.listen(backlog)
    rescue Exception
      sock.close
      raise
    end
    if block_given?
      begin
        yield sock
      ensure
        sock.close if !sock.closed?
      end
    else
      sock
    end
  end

  # iterates over the list of Addrinfo objects obtained by Addrinfo.getaddrinfo.
  #
  #   Addrinfo.foreach(nil, 80) {|x| p x }
  #   #=> #<Addrinfo: 127.0.0.1:80 TCP (:80)>
  #   #   #<Addrinfo: 127.0.0.1:80 UDP (:80)>
  #   #   #<Addrinfo: [::1]:80 TCP (:80)>
  #   #   #<Addrinfo: [::1]:80 UDP (:80)>
  #
  def self.foreach(nodename, service, family=nil, socktype=nil, protocol=nil, flags=nil, &block)
    Addrinfo.getaddrinfo(nodename, service, family, socktype, protocol, flags).each(&block)
  end
end
