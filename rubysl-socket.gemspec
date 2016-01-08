# coding: utf-8
require './lib/rubysl/socket/version'

Gem::Specification.new do |spec|
  spec.name          = "rubysl-socket"
  spec.version       = RubySL::Socket::VERSION
  spec.authors       = ["Brian Shirai", "Yorick Peterse"]
  spec.email         = ["brixen@gmail.com", "yorickpeterse@gmail.com"]
  spec.description   = %q{Socket standard library for Rubinius.}
  spec.summary       = %q{Socket standard library for Rubinius.}
  spec.homepage      = "https://github.com/rubysl/rubysl-socket"
  spec.license       = "BSD"

  spec.files = Dir.glob([
    'lib/**/*.*',
    'LICENSE',
    'README.md',
    'rubysl-socket.gemspec'
  ])

  spec.required_ruby_version = '~> 2.0'

  spec.add_dependency 'rubysl-fcntl', '~> 2.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "mspec", "~> 1.9"
  spec.add_development_dependency "rubysl-prettyprint", "~> 2.0"
  spec.add_development_dependency "rubysl-ipaddr", "~> 2.0"
end
