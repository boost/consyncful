require "consyncful/version"

require 'mongoid'
require 'contentful'

require "consyncful/base"
require "consyncful/sync"

require "consyncful/railtie" if defined?(Rails)

module Consyncful
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :contentful_client_options, :locale

    def initialize
      @contentful_client_options = {
        api_url: 'cdn.contentful.com'
      }
      @locale = 'en-US'
    end
  end

  DEFAULT_CLIENT_OPTIONS = {
    reuse_entries: true,
    api_url: 'cdn.contentful.com'
  }

  def self.client
    @client ||= begin
      options = Consyncful.configuration.contentful_client_options
      options.reverse_merge!(DEFAULT_CLIENT_OPTIONS)

      Contentful::Client.new(options)
    end
  end
end
