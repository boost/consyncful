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
    DEFAULT_CLIENT_OPTIONS = {
      reuse_entries: true,
      api_url: 'cdn.contentful.com'
    }.freeze

    # see https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/synchronization
    DEFAULT_SYNC_OPTIONS = {
      limit: 100,
      type: 'all'
    }.freeze

    attr_accessor :contentful_client_options,
                  :contentful_sync_options,
                  :locale,
                  :mongo_client,
                  :mongo_collection,
                  :content_tags,
                  :ignore_content_tags,
                  :preserve_contentful_timestamps

    def initialize
      @contentful_client_options = {}
      @contentful_sync_options = {}
      @locale = 'en-NZ'
      @mongo_client = :default
      @mongo_collection = 'contentful_models'
      @content_tags = []
      @ignore_content_tags = []
      @preserve_contentful_timestamps = false
    end

    def initial_sync_options
      options = { initial: true }
      options = options.reverse_merge(@contentful_sync_options)
      options.reverse_merge(DEFAULT_SYNC_OPTIONS)
    end

    def client_options
      options = @contentful_client_options
      options.reverse_merge!(DEFAULT_CLIENT_OPTIONS)
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def client
      @client ||= Contentful::Client.new(Consyncful.configuration.client_options)
    end
  end
end
