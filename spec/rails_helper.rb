# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'bundler/setup'
require 'combustion'
require 'consyncful'
require 'consyncful/engine'

Combustion.initialize! :action_controller, :active_support

require 'rspec/rails'

RSpec.configure do |config|
  config.use_active_record = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
