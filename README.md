# rubysl-socket

An implementation of the Ruby socket standard library for Rubinius, written
using Ruby and FFI (and a tiny bit of C++ defined in Rubinius itself). More
information about the socket standard library can be found at
<http://ruby-doc.org/stdlib/libdoc/socket/rdoc/index.html>.

Please note that **only** Rubinius is officially supported. While other Ruby
implementations are free to use rubysl-socket according to its license we do not
provide any support for this.

Issues for the socket standard library in general should be reported at
<https://bugs.ruby-lang.org/>, **only** use this project's issue tracker for
reporting issues with the Gem itself (e.g. something isn't implemented
correctly).

## Target

The 2.0 branch of rubysl-socket targets Ruby 2.x, other Ruby versions are
currently not supported.

## Requirements

* Rubinius 2.9 or newer
* A POSIX compliant operating system

Windows is currently not supported and there are no plans to support it for the
foreseeable future. The Rubinius team sadly lacks the capacity and experience to
support Windows besides also supporting the countless Linux and BSD
distributions out there.

## Installation

By default rubysl-socket is already installed when you install Rubinius.
Currently updating rubysl-socket requires re-installing Rubinius, in the future
you can simply update rubysl-socket by running `gem update rubysl-socket`.

## Contributing

In general the contributing guidelines are the same as Rubinius
(<http://rubinius.com/doc/en/contributing/>). The structure of this repository
is as following:

* `lib/rubysl/socket/`: contains all code living under the `RubySL::Socket`
  namespace, mostly used for FFI code, helper methods, etc.
* `lib/socket/`: contains the code of the public socket APIs such as `Socket`,
  `TCPSocket`, etc. Code in this directory should not refer to the `Rubinius`
  namespace directly, instead use (or create) methods defined under the
  `RubySL::Socket` namespace.
* `spec/`: all mspec specs

To get started, clone the directory and install all Gems:

    bundle install

You'll want to do this for both your local CRuby and Rubinius installations.

Running the specs under CRuby works as following:

    mspec spec/path/to/file_spec.rb

Running the specs under Rubinius requires an extra environment variable so
Rubinius loads the local rubysl-socket copy instead of the installed one:

    RUBYLIB=.:lib mspec spec/path/to/file_spec.rb

All specs **must** pass on both CRuby and Rubinius.

## License

rubysl-socket is licensed under the BSD license unless stated otherwise, a copy
of this license can be found in the file "LICENSE". The MRI source code found in
`lib/socket/mri.rb` is licensed under the same license as Ruby, a copy of this
license can be found in the file itself.
