# frozen_string_literal: true

module Consyncful
  class WebhookController < ActionController::API
    def create
      return head :not_found unless Consyncful.configuration.use_webhooks?

      # TODO: Verify the request

      Consyncful::Sync.signal_webhook!
      head :accepted
    end
  end
end
