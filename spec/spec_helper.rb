# frozen_string_literal: true

require 'bundler/setup'
require 'consyncful'
require 'database_cleaner/mongoid'

Mongoid.load!('spec/support/mongoid.yml', :test)

DatabaseCleaner.strategy = :deletion

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.before(:each) do
    DatabaseCleaner.clean_with(:deletion)
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
