# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitia-rails/version'

Gem::Specification.new do |spec|
  spec.name = 'bitia-rails'
  spec.version = Bitia::Rails::VERSION
  spec.authors = ['Artem Levenkov']
  spec.email = ['alev@bitia.ru']
  spec.summary = "Common modules for Bitia’s Rails projects"
  spec.homepage = 'https://github.com/bitia-ru/bitia-rails'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']
end
