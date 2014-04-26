# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mumblr/version'

Gem::Specification.new do |spec|
  spec.name          = "mumblr"
  spec.version       = Mumblr::VERSION
  spec.authors       = ["Liam Bowen"]
  spec.email         = ["LiamBowen@gmail.com"]
  spec.summary       = %q{A utility and library for archiving Tumblr posts}
  #spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "tumblr_client"
  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "progressbar"
  spec.add_runtime_dependency "data_mapper"
  spec.add_runtime_dependency "dm-sqlite-adapter"
  spec.add_runtime_dependency "awesome_print"
  spec.add_runtime_dependency "youtube-downloader"


  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
end
