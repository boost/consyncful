# frozen_string_literal: true

module Consyncful
  class WebhookController < ActionController::API
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    before_action :authenticate, if: -> { Consyncful.configuration.use_webhooks? }

    def create
      return head :not_found unless Consyncful.configuration.use_webhooks?

      Consyncful::Sync.signal_webhook!
      head :accepted
    end

    private

    def authenticate
      config = Consyncful.configuration
      authenticate_or_request_with_http_basic('Consyncful: Authenticate to Trigger Sync') do |user, pass|
        secure_compare(user, config.resolved_webhook_user) && secure_compare(pass, config.resolved_webhook_password)
      end
    end

    def secure_compare(a, b)
      ActiveSupport::SecurityUtils.secure_compare(a.to_s, b.to_s)
    end
  end
end
