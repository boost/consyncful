# frozen_string_literal: true

module Consyncful
  class WebhookController < ActionController::API
    def create
      head :accepted
    end
  end
end
