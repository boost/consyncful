# frozen_string_literal: true
module Consyncful
  module Config
    class Webhook
      attr_accessor :enabled, :path, :secret, :ttl_seconds, :accept_topics

      def initialize
        @enabled       = false
        @path          = '/consyncful/webhook'
        @secret        = ENV['CONSYNCFUL_WEBHOOK_SECRET']
        @ttl_seconds   = 60
        @accept_topics = %w[ContentManagement.Entry.* ContentManagement.Asset.*]
      end
    end
  end
end
