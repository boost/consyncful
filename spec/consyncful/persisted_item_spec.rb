# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consyncful::PersistedItem do
  let(:stats) { instance_double('Consyncful::Stats') }
  let(:sync_id) { rand(100..200) }
  let(:persisted_item) { Consyncful::PersistedItem.new(item, sync_id, stats) }

  context 'when the item is a deletion' do
    let(:item) { instance_double('Consyncful::ItemMapper', deletion?: true, id: 'itemId') }
    let(:instance) { instance_double('Consyncful::Base') }

    before do
      allow(stats).to receive(:record_deleted)
    end

    it 'finds the model and destroys it' do
      expect(Consyncful::Base).to receive(:find_by).with(id: 'itemId').and_return(instance)
      expect(instance).to receive(:destroy)
      persisted_item.persist
    end
  end

  context 'when the item is a create or update' do
    let(:mapped_fields) { { field_name: 'value', other_field: 3 } }
    let(:item) { instance_double('Consyncful::ItemMapper', deletion?: false, id: 'itemId', type: 'itemType', mapped_fields: mapped_fields) }
    let(:instance) { instance_double('Consyncful::Base', persisted?: false, save: true, :[]= => nil, attributes: []) }

    before do
      allow(stats).to receive(:record_added)
    end

    # rubocop:disable Style/ClassAndModuleChildren
    class self::TestContentfulType < Consyncful::Base
      contentful_model_name 'itemType'
    end
    # rubocop:enable Style/ClassAndModuleChildren
    let(:klass) { self.class::TestContentfulType }

    it 'finds the model of the correct type' do
      expect(klass).to receive(:find_or_initialize_by).with(id: 'itemId').and_return(instance)
      persisted_item.persist
    end

    it 'assigns all mapped fields' do
      allow(klass).to receive(:find_or_initialize_by).with(id: 'itemId').and_return(instance)
      expect(instance).to receive(:[]=).with(:field_name, 'value')
      expect(instance).to receive(:[]=).with(:other_field, 3)
      persisted_item.persist
    end

    it 'sets the sync id on the item' do
      allow(klass).to receive(:find_or_initialize_by).with(id: 'itemId').and_return(instance)
      expect(instance).to receive(:[]=).with(:sync_id, sync_id)
      persisted_item.persist
    end

    it 'nils all other fields' do
      skip 'need this test'
    end

    it 'saves the item' do
      allow(klass).to receive(:find_or_initialize_by).with(id: 'itemId').and_return(instance)
      expect(instance).to receive(:save)
      persisted_item.persist
    end
  end
end
