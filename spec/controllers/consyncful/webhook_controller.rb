# frozen_string_literal: true

RSpec.describe Consyncful::WebhookController, type: :controller do
  routes { Consyncful::Engine.routes }

  let(:config) { Consyncful.configuration }

  context 'when webhooks are disabled' do
    it 'returns 404 and does not signal' do
      allow(config).to receive(:use_webhooks?).and_return(false)
      expect(Consyncful::Sync).not_to receive(:signal_webhook!)

      post :create # POST /webhook
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when webhooks are enabled' do
    before do
      Consyncful.configure do |c|
        c.sync_mode = :webhook
        c.webhook_user = 'user'
        c.webhook_password = 'pass'
      end
      allow(Consyncful.configuration).to receive(:use_webhooks?).and_return(true)
    end

    it 'requires HTTP Basic auth' do
      post :create
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['WWW-Authenticate']).to include('Basic realm="Consyncful: Authenticate to Trigger Sync"')
    end

    it 'rejects wrong credentials' do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('bad', 'creds')
      post :create
      expect(response).to have_http_status(:unauthorized)
    end

    it 'accepts correct credentials and signals webhook' do
      allow(Consyncful::Sync).to receive(:signal_webhook!).and_return(true)

      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials('user', 'pass')

      post :create
      expect(response).to have_http_status(:accepted)
      expect(Consyncful::Sync).to have_received(:signal_webhook!)
    end
  end
end
