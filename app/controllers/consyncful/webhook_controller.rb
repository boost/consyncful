# frozen_string_literal: true

module Consyncful
  class WebhookController < ActionController::API
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    before_action :authenticate, if: -> { Consyncful.configuration.webhook_authentication_required && use_webhooks? }

    def trigger_sync
      return head :not_found unless use_webhooks?

      Consyncful::Sync.signal_webhook!
      head :accepted
    end

    private

    def use_webhooks?
      Consyncful.configuration.sync_mode == :webhook
    end

    def authenticate
      config = Consyncful.configuration
      authenticate_or_request_with_http_basic('Consyncful: Authenticate to Trigger Sync') do |username, password|
        secure_compare(username, config.webhook_user) && secure_compare(password, config.webhook_password)
      end
    end

    def secure_compare(value, expected)
      ActiveSupport::SecurityUtils.secure_compare(value.to_s, expected.to_s)
    end
  end
end
