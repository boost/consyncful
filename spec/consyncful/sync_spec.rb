# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consyncful::Sync do
  describe '.drop_stale' do
    let(:sync1) { Consyncful::Sync.create }
    let(:sync2) { Consyncful::Sync.create }
    let!(:record1) { Consyncful::Base.create(sync_id: sync1.id) }
    let!(:record2) { Consyncful::Base.create(sync_id: sync1.id) }
    let!(:record3) { Consyncful::Base.create(sync_id: sync2.id) }

    it 'destroys all records that werent synced by this sync' do
      sync2.drop_stale
      expect(Consyncful::Base.count).to eq 1
      expect(Consyncful::Base.all).to include(record3)
    end

    it 'does not destroy records with no sync_id' do
      record2.unset(:sync_id)
      sync2.drop_stale
      expect(Consyncful::Base.count).to eq 2
      expect(Consyncful::Base.all).to include(record2, record3)
    end
  end

  describe 'callbacks' do
    let(:client) { instance_double('Contentful::Client', sync: client_sync) }
    let(:client_sync) { instance_double('Contentful::Sync', each_page: [], next_sync_url: 'next_url') }
    let(:sync) { Consyncful::Sync.create }

    before do
      allow(Consyncful).to receive(:client).and_return(client)
    end

    describe 'before run' do
      let(:callback) do
        Proc.new { puts 'test before callback!' }
      end

      it 'executes hook before run' do
        Consyncful::Sync.before_run callback
        expect{sync.run}.to output(/\Atest before callback!/).to_stdout
      end

      after do
        Consyncful::Sync.callbacks_for_hook(:before_run).clear
      end
    end

    describe 'after run' do
      let(:page) do
        double('page', items: [double('item')])
      end
      let(:mapper) { instance_double('Consyncful::ItemMapper', id: 'itemId', deletion?: true) }

      before do
        allow(client_sync).to receive(:each_page).and_yield(page)
        allow(Consyncful::ItemMapper).to receive(:new).and_return(mapper)
      end

      let(:callback) do
        Proc.new {|ids| puts "test after callback with #{ids.join(', ')}" }
      end

      it 'executes hook after run and provides updated ids' do
        Consyncful::Sync.after_run callback
        expect { sync.run }.to output(/test after callback with #{['itemId'].join(', ')}/).to_stdout
      end

      after do
        Consyncful::Sync.callbacks_for_hook(:after_run).clear
      end
    end
  end

  describe '#run' do
    let(:client) { instance_double('Contentful::Client', sync: client_sync) }
    let(:client_sync) { instance_double('Contentful::Sync', each_page: [], next_sync_url: 'next_url') }
    before do
      allow(Consyncful).to receive(:client).and_return(client)
    end

    it 'starts a new sync when there is no next_url' do
      expect(client).to receive(:sync).with(initial: true).and_return(client_sync)
      Consyncful::Sync.new.run
    end

    it 'resumes sync when there is a next_url' do
      expect(client).to receive(:sync).with('previous_url').and_return(client_sync)
      Consyncful::Sync.new(next_url: 'previous_url', last_run_at: Time.now).run
    end

    it 'saves the next url' do
      sync = Consyncful::Sync.create
      sync.run
      expect(sync.next_url).to eq 'next_url'
    end

    it 'saves the current run time' do
      time = Time.current
      expect(Time).to receive(:current).and_return(time)
      sync = Consyncful::Sync.create
      sync.run
      expect(sync.last_run_at).to eq time
    end

    context 'when there are items to sync' do
      let(:sync) { Consyncful::Sync.create }
      let(:page) do
        double('page', items: [double('item')])
      end
      let(:mapper) { instance_double('Consyncful::ItemMapper') }

      before do
        allow(client_sync).to receive(:each_page).and_yield(page)
        allow(Consyncful::ItemMapper).to receive(:new).and_return(mapper)
      end

      context 'when the item is a deletion' do
        let(:mapper) { instance_double('Consyncful::ItemMapper', deletion?: true, id: 'itemId') }
        let(:instance) { instance_double('Consyncful::Base') }

        it 'finds the model and destroys it' do
          expect(Consyncful::Base).to receive(:find_by).with(id: 'itemId').and_return(instance)
          expect(instance).to receive(:destroy)
          sync.run
        end
      end

      context 'when the item is a create or update' do
        let(:mapped_fields) { { field_name: 'value', other_field: 3 } }
        let(:mapper) { instance_double('Consyncful::ItemMapper', deletion?: false, id: 'itemId', type: 'itemType', mapped_fields: mapped_fields) }
        let(:instance) { instance_double('Consyncful::Base', persisted?: false, save: true, :[]= => nil, attributes: []) }

        class self::TestContentfulType < Consyncful::Base
          contentful_model_name 'itemType'
        end
        let(:klass) { self.class::TestContentfulType }

        it 'finds the model of the correct type' do
          expect(klass).to receive(:find_or_initialize_by).with(id: 'itemId').and_return(instance)
          sync.run
        end

        it 'assigns all mapped fields' do
          allow(klass).to receive(:find_or_initialize_by).with(id: 'itemId').and_return(instance)
          expect(instance).to receive(:[]=).with(:field_name, 'value')
          expect(instance).to receive(:[]=).with(:other_field, 3)
          sync.run
        end

        it 'sets the sync id on the item' do
          allow(klass).to receive(:find_or_initialize_by).with(id: 'itemId').and_return(instance)
          expect(instance).to receive(:[]=).with(:sync_id, sync.id)
          sync.run
        end

        it 'nils all other fields' do
          skip 'need this test'
        end

        it 'saves the iteam' do
          allow(klass).to receive(:find_or_initialize_by).with(id: 'itemId').and_return(instance)
          expect(instance).to receive(:save)
          sync.run
        end
      end
    end
  end
end
