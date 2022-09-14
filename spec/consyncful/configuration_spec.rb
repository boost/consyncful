# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consyncful::Configuration do
  describe '.initial_sync_options' do
    let(:configuration) { Consyncful::Configuration.new }

    context 'when configuration is not overridden' do
      it 'contains initial:true' do
        result = configuration.initial_sync_options
        expect(result[:initial]).to be_truthy
      end

      it 'contains all the DEFAULT_SYNC_OPTIONS' do
        result = configuration.initial_sync_options
        Consyncful::DEFAULT_SYNC_OPTIONS.each do |key, value|
          expect(result[key]).to eq value
        end
      end
    end

    context 'when initial:true is overridden' do
      it 'stays as initial:true' do
        configuration.contentful_sync_options = { initial: false }
        result = configuration.initial_sync_options
        expect(result[:initial]).to be_truthy
      end
    end

    context 'when an option defined in DEFAULT_SYNC_OPTIONS is overridden' do
      it 'is respected' do
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

end