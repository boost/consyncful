# frozen_string_literal: true

require 'consyncful/version'

require 'mongoid'
require 'contentful'

require 'consyncful/base'
require 'consyncful/sync'

require 'consyncful/railtie' if defined?(Rails)

module Consyncful
  # Handles Rails configurations for Consynful
  class Configuration
    attr_accessor :contentful_client_options,
                  :locale,
                  :mongo_client,
                  :mongo_collection,
                  :content_tags,
                  :ignore_content_tags

    def initialize
      @contentful_client_options = {
        api_url: 'cdn.contentful.com'
      }
      @locale = 'en-NZ'
      @mongo_client = :default
      @mongo_collection = 'contentful_models'
      @content_tags = []
      @ignore_content_tags = []
    end
  end

  DEFAULT_CLIENT_OPTIONS = {
    reuse_entries: true,
    api_url: 'cdn.contentful.com'
  }.freeze

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def client
      @client ||= begin
        options = Consyncful.configuration.contentful_client_options
        options.reverse_merge!(DEFAULT_CLIENT_OPTIONS)
        Contentful::Client.new(options)
      end
    end
  end
end
