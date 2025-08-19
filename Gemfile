# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }
# Specify your gem's dependencies in consyncful.gemspec
gemspec

group :development do
  gem 'bundler', '~> 2'
  gem 'rake', '~> 13.0'
  gem 'rubocop'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
end

group :development, :test do
  gem 'combustion', '~> 1.3'
  gem 'rspec', '~> 3.13'
  gem 'rspec-rails', '~> 6.1'
end

group :test do
  gem 'database_cleaner-mongoid', '~> 2.0'
end
