# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consyncful::ItemMapper do
  let(:entry_json) do
    {
      'sys' => {
        'space' => { 'sys' => { 'type' => 'Link', 'linkType' => 'Space', 'id' => 'spaceId' } },
        'id' => 'itemID',
        'type' => 'Entry',
        'createdAt' => '2019-02-20T00:50:17.357Z',
        'updatedAt' => '2019-02-20T00:50:50.052Z',
        'environment' => { 'sys' => { 'id' => 'master', 'type' => 'Link', 'linkType' => 'Environment' } },
        'revision' => 43,
        'contentType' => { 'sys' => { 'type' => 'Link', 'linkType' => 'ContentType', 'id' => 'typeName' } }
      },
      'fields' => {
        'description' => { 'en-NZ' => 'Govt loan reg text' },
        'text' => {
          'en-NZ' => {
            'nodeType' => 'document',
            'data' => {},
            'content' => [{ 'nodeType' => 'paragraph', 'content' => [{ 'nodeType' => 'text', 'value' => 'To register as a government loans client please fill in the form below.', 'marks' => [], 'data' => {} }], 'data' => {} }]
          }
        }
      }
    }
  end
  let(:contentful_entry) { Contentful::Entry.new(entry_json, {}, true) }

  let(:asset_json) do
    {
      'sys' => {
        'space' => { 'sys' => { 'type' => 'Link', 'linkType' => 'Space', 'id' => 'spaceId' } },
        'id' => 'itemId',
        'type' => 'Asset',
        'createdAt' => '2019-02-12T23:28:33.756Z',
        'updatedAt' => '2019-02-20T02:50:59.780Z',
        'environment' => { 'sys' => { 'id' => 'development', 'type' => 'Link', 'linkType' => 'Environment' } },
        'revision' => 3
      },
      'fields' => {
        'title' => { 'en-NZ' => 'BBBW 5009 7a01 Hero image' },
        'description' => { 'en-NZ' => 'Test' },
        'file' => {
          'en-NZ' => {
            'url' => 'imageUrl',
            'details' => { 'size' => 196_189, 'image' => { 'width' => 1441, 'height' => 595 } },
            'fileName' => 'Hero image.jpg',
            'contentType' => 'image/jpeg'
          }
        }
      }
    }
  end
  let(:contentful_asset) { Contentful::Asset.new(asset_json, {}, true) }

  describe '#type' do
    context 'when the item is an entry' do
      let(:item) { Consyncful::ItemMapper.new(contentful_entry) }

      it 'type returns the contentful typeName' do
        expect(item.type).to eq 'typeName'
      end
    end

    context 'when the item is an asset' do
      let(:item) { Consyncful::ItemMapper.new(contentful_asset) }

      it 'type returns asset' do
        expect(item.type).to eq 'asset'
      end
    end
  end

  describe '#id' do
    let(:item) { Consyncful::ItemMapper.new(contentful_entry) }

    it 'returns the entrys id' do
      expect(item.id).to eq contentful_entry.id
    end
  end

  describe '#mapped_fields' do
    let(:item) { Consyncful::ItemMapper.new(contentful_entry) }

    it 'returns the generic fields' do
      expect(item.mapped_fields('en-NZ')).to include(
        created_at: DateTime.parse('2019-02-20T00:50:17.357Z'),
        updated_at: DateTime.parse('2019-02-20T00:50:50.052Z'),
        revision: 43,
        contentful_type: 'typeName'
      )
    end

    it 'returns a field called synced_at with the current time' do
      dummy_time = double('time')
      expect(Time).to receive(:current).and_return(dummy_time)
      expect(item.mapped_fields('en-NZ')).to include(synced_at: dummy_time)
    end

    it 'returns all normal fields from the requested locale' do
      expect(item.mapped_fields('en-NZ')).to include(
        description: 'Govt loan reg text',
        text: {
            'nodeType' => 'document',
            'data' => {},
            'content' => [{ 'nodeType' => 'paragraph', 'content' => [{ 'nodeType' => 'text', 'value' => 'To register as a government loans client please fill in the form below.', 'marks' => [], 'data' => {} }], 'data' => {} }]
          }
      )
    end

    context 'when the entry includes reference fields' do
      before do
        entry_json['fields']['manyRefs'] = {
          "en-NZ" => [
            {"sys"=>{"type"=>"Link", "linkType"=>"Entry", "id"=>"5MLrvU144Mg0OQIwIyeWea"}},
            {"sys"=>{"type"=>"Link", "linkType"=>"Entry", "id"=>"11baJLRlumIIGEqOGaUW0Y"}}
          ]
        }
        entry_json['fields']['oneRef'] = {
          "en-NZ" => {"sys"=>{"type"=>"Link", "linkType"=>"Entry", "id"=>"5MLrvU144Mg0OQIwIyeWea"}},
        }
      end

      it 'returns many refs as an array of ids in a field the the correct name for mongoid' do
        expect(item.mapped_fields('en-NZ')).to include(many_ref_ids: ['5MLrvU144Mg0OQIwIyeWea', '11baJLRlumIIGEqOGaUW0Y'])
      end

      it 'returns one refs as the correct name for mongoid' do
        expect(item.mapped_fields('en-NZ')).to include(one_ref_id: '5MLrvU144Mg0OQIwIyeWea')
      end
    end

    context 'when the item is an asset' do
      let(:item) { Consyncful::ItemMapper.new(contentful_asset) }

      it 'returns the correct file details' do
        expect(item.mapped_fields('en-NZ')[:file]).to include(
          'url' => 'imageUrl',
          'details' => { 'size' => 196_189, 'image' => { 'width' => 1441, 'height' => 595 } },
          'fileName' => 'Hero image.jpg',
          'contentType' => 'image/jpeg'
        )
      end
    end
  end

  describe '#deletion?' do
    it 'returns false when the item is an Entry or Asset' do
      expect(Consyncful::ItemMapper.new(contentful_entry).deletion?).to eq false
      expect(Consyncful::ItemMapper.new(contentful_asset).deletion?).to eq false
    end

    context 'when the item is a DeletedEntry or an DeletedAsset' do
      let(:deleted_item_json) do
        {"sys"=>
          {"type"=>"DeletedEntry",
           "id"=>"itemID",
           "space"=>{"sys"=>{"type"=>"Link", "linkType"=>"Space", "id"=>"spaceId"}},
           "environment"=>{"sys"=>{"id"=>"master", "type"=>"Link", "linkType"=>"Environment"}},
           "revision"=>1,
           "createdAt"=>"2019-02-20T18:25:21.515Z",
           "updatedAt"=>"2019-02-20T18:25:21.515Z",
           "deletedAt"=>"2019-02-20T18:25:21.515Z"}}
      end
      it 'returns true' do
        deleted_item = Contentful::DeletedEntry.new(deleted_item_json, {}, true)
        deleted_item_json["sys"]["type"] = 'DeletedAsset'
        deleted_asset = Contentful::DeletedAsset.new(deleted_item_json, {}, true)

        expect(Consyncful::ItemMapper.new(deleted_item).deletion?).to eq true
        expect(Consyncful::ItemMapper.new(deleted_asset).deletion?).to eq true
      end
    end
  end
end
