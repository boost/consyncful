# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consyncful::Configuration do
  let(:configuration) { Consyncful::Configuration.new }

  it 'defaults to poll sync_mode' do
    expect(configuration.sync_mode).to eq(:poll)
  end

  describe '.initial_sync_options' do
    it 'always contains initial:true' do
      result = configuration.initial_sync_options
      expect(result[:initial]).to be_truthy
    end

    context 'when initial:true is attempted to be overridden' do
      it 'does not respect the override' do
        configuration.contentful_sync_options = { initial: false }
        result = configuration.initial_sync_options
        expect(result[:initial]).to be_truthy
      end
    end

    context 'when options are not overridden' do
      it 'contains all the DEFAULT_SYNC_OPTIONS' do
        result = configuration.initial_sync_options
        Consyncful::DEFAULT_SYNC_OPTIONS.each do |key, value|
          expect(result[key]).to eq value
        end
      end
    end

    context 'when an option defined in DEFAULT_SYNC_OPTIONS is overridden' do
      it 'respects the override' do
        configuration.contentful_sync_options = { limit: 2 }
        result = configuration.initial_sync_options
        expect(result[:limit]).to eq 2
      end

      it 'also contains the other DEFAULT_SYNC_OPTIONS' do
        result = configuration.initial_sync_options
        Consyncful::DEFAULT_SYNC_OPTIONS.each do |key, value|
          next if key == :limit

          expect(result[key]).to eq value
        end
      end
    end

    context 'when a new option is defined' do
      it 'is included' do
        configuration.contentful_sync_options = { crazy_new_option: 123 }
        result = configuration.initial_sync_options
        expect(result[:crazy_new_option]).to eq 123
      end
    end
  end

  describe '.client_options' do
    context 'when options are not overridden' do
      it 'uses the default values' do
        result = configuration.client_options
        Consyncful::DEFAULT_CLIENT_OPTIONS.each do |key, value|
          expect(result[key]).to eq value
        end
      end

      it 'does not add any more options other than the defaults' do
        result = configuration.client_options
        expect(result.count).to eq Consyncful::DEFAULT_CLIENT_OPTIONS.count
      end
    end

    context 'when options are overridden' do
      it 'respects the override' do
        configuration.contentful_client_options = { api_url: 'custom.api.url' }
        result = configuration.client_options
        expect(result[:api_url]).to eq 'custom.api.url'
      end

      it 'falls back to the default values' do
        result = configuration.client_options
        Consyncful::DEFAULT_CLIENT_OPTIONS.each do |key, value|
          next if key == :api_url

          expect(result[key]).to eq value
        end
      end
    end
  end
end
