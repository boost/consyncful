# frozen_string_literal: true

require 'consyncful/version'

require 'mongoid'
require 'contentful'

require 'consyncful/base'
require 'consyncful/sync'

require 'consyncful/railtie' if defined?(Rails)

module Consyncful
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  # Rails configurations for Consynful
  class Configuration
    attr_accessor :contentful_client_options, :locale

    def initialize
      @contentful_client_options = {
        api_url: 'cdn.contentful.com'
      }
      @locale = 'en-NZ'
    end
  end

  DEFAULT_CLIENT_OPTIONS = {
    reuse_entries: true,
    api_url: 'cdn.contentful.com'
  }.freeze

  def self.client
    @client ||= begin
      options = Consyncful.configuration.contentful_client_options
      options.reverse_merge!(DEFAULT_CLIENT_OPTIONS)
      Contentful::Client.new(options)
    end
  end
end
