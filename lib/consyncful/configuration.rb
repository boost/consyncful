# frozen_string_literal: true

require 'consyncful/config/webhook'
require 'consyncful/config/jobs'
require 'consyncful/config/debounce'
require 'consyncful/config/lock'

# Handles Rails configurations for Consyncful
module Consyncful
  class Configuration
    attr_accessor :contentful_client_options,
                  :contentful_sync_options,
                  :locale,
                  :mongo_client,
                  :mongo_collection,
                  :content_tags,
                  :ignore_content_tags,
                  :preserve_contentful_timestamps,
                  :sync_mode

    attr_reader :webhook, :jobs, :debounce, :lock

    def initialize
      @sync_mode = :poll
      @contentful_client_options = {}
      @contentful_sync_options = {}
      @locale = 'en-NZ'
      @mongo_client = :default
      @mongo_collection = 'contentful_models'
      @content_tags = []
      @ignore_content_tags = []
      @preserve_contentful_timestamps = false

      @webhook = Config::Webhook.new
      @jobs = Config::Jobs.new
      @debounce = Config::Debounce.new
      @lock = Config::Lock.new
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

    def use_webhooks?
      webhook.enabled && webhook.secret.present?
    end

    def webhook_path;           webhook.path;            end
    def webhook_secret;         webhook.secret;          end
    def webhook_ttl_seconds;    webhook.ttl_seconds;     end
    def webhook_accept_topics;  webhook.accept_topics;   end

    def job_queue;              jobs.queue;              end
    def debounce_window;        debounce.window_seconds; end

    def lock_backend;           lock.backend;            end
    def lock_ttl_seconds;       lock.ttl_seconds;        end
  end

  DEFAULT_CLIENT_OPTIONS = {
    reuse_entries: true,
    api_url: 'cdn.contentful.com'
  }.freeze

  # see https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/synchronization
  DEFAULT_SYNC_OPTIONS = {
    limit: 100,
    type: 'all'
  }.freeze

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
