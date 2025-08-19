# frozen_string_literal: true

# External dependencies
require 'mongoid'
require 'contentful'

# Internal library files
require 'consyncful/version'
require 'consyncful/configuration'
require 'consyncful/base'
require 'consyncful/sync'

# Rails integration (only load if Rails is present)
if defined?(Rails)
  require 'consyncful/railtie'
  require 'consyncful/engine'
end
