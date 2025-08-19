# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Consyncful::WebhookController', type: :request do
  let(:config) do
    # Provide a simple configuration double with the fields used by the controller
    instance_double(
      'Consyncful::Configuration',
      sync_mode: sync_mode,
      webhook_authentication_required: auth_required,
      webhook_user: 'user1',
      webhook_password: 'secret'
    )
  end

  before do
    allow(Consyncful).to receive(:configuration).and_return(config)
  end

  describe 'POST /consyncful/webhook' do
    subject(:perform) { post '/consyncful/webhook', headers: headers }

    let(:headers) { {} }

    context 'when sync mode is not :webhook' do
      let(:sync_mode) { :poll }
      let(:auth_required) { false }

      it 'returns 404 Not Found' do
        perform
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when sync mode is :webhook' do
      let(:sync_mode) { :webhook }

      context 'and authentication is not required' do
        let(:auth_required) { false }

        it 'signals the sync and returns 202 Accepted' do
          expect(Consyncful::Sync).to receive(:signal_webhook!)
          perform
          expect(response).to have_http_status(:accepted)
        end
      end

      context 'and authentication is required' do
        let(:auth_required) { true }

        context 'with no credentials' do
          it 'returns 401 Unauthorized' do
            perform
            expect(response).to have_http_status(:unauthorized)
          end
        end

        context 'with wrong credentials' do
          let(:headers) do
            {
              'HTTP_AUTHORIZATION' =>
                ActionController::HttpAuthentication::Basic.encode_credentials('user1', 'wrong')
            }
          end

          it 'returns 401 Unauthorized' do
            perform
            expect(response).to have_http_status(:unauthorized)
          end
        end

        context 'with correct credentials' do
          let(:headers) do
            {
              'HTTP_AUTHORIZATION' =>
                ActionController::HttpAuthentication::Basic.encode_credentials('user1', 'secret')
            }
          end

          it 'signals the sync and returns 202 Accepted' do
            expect(Consyncful::Sync).to receive(:signal_webhook!)
            perform
            expect(response).to have_http_status(:accepted)
          end
        end
      end
    end
  end
end
