# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'codestart/version'

Gem::Specification.new do |spec|
  spec.name          = 'codestart'
  spec.version       = Codestart::VERSION
  spec.authors       = ['ben7th']
  spec.email         = ['ben7th@sina.com']
  spec.summary       = 'code generator'
  spec.description   = 'a code generator of mindpin team for starting a new project.'
  spec.homepage      = 'https://github.com/mindpin/codestart'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").select {|x| !x.match /.gem$/}
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 0'

  spec.add_runtime_dependency 'activesupport', '~> 4.2', '>= 4.2.0'
end
