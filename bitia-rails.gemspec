$:.push File.expand_path('lib', __dir__)

require 'bitia/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name = 'bitia-rails'
  spec.version = Bitia::VERSION
  spec.authors = ['Artem Levenkov']
  spec.email = ['alev@bitia.ru']
  spec.summary = 'Common modules for Bitia’s Rails projects'
  spec.homepage = 'https://github.com/bitia-ru/bitia-rails'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.add_dependency 'rails', '~> 5.2.4', '>= 5.2.4.3'
  spec.add_dependency 'responders'

  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'sqlite3'
end
