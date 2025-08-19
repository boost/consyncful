# frozen_string_literal: true

module Consyncful
  # The Consyncful::WebhookController is responsible for handling incoming
  # webhook requests that can trigger synchronization jobs within Consyncful.
  #
  # Features:
  # - Only responds to requests if `sync_mode` is configured as `:webhook`.
  # - Optionally requires HTTP Basic authentication if
  #   `webhook_authentication_required` is enabled in configuration.
  # - Exposes a single endpoint (`trigger_sync`) that signals a sync process
  #   through `Consyncful::Sync.signal_webhook!`.
  #
  # Security:
  # - Uses `ActionController::HttpAuthentication::Basic` to enforce
  #   authentication when enabled.
  # - Compares provided credentials with configured values using
  #   `ActiveSupport::SecurityUtils.secure_compare` to prevent timing attacks.
  #
  # Responses:
  # - Returns `404 Not Found` if webhooks are not enabled.
  # - Returns `202 Accepted` after signaling a sync.
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
