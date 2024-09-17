# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'consyncful/version'

Gem::Specification.new do |spec|
  spec.name                  = 'consyncful'
  spec.version               = Consyncful::VERSION
  spec.required_ruby_version = '>= 2.7'
  spec.authors               = ['Andy Anastasiadis-Gray']
  spec.email                 = ['andy@boost.co.nz']

  spec.summary  = 'Contentful to local database synchronisation for Rails'
  spec.homepage = 'https://github.com/boost/consyncful'
  spec.license  = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'

  spec.add_dependency 'contentful', '~> 2.16.3'
  spec.add_dependency 'hooks', '>=0.4.1'
  spec.add_dependency 'mongoid', '~> 9'
  spec.add_dependency 'rainbow'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
