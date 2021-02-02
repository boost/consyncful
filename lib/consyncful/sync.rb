# frozen_string_literal: true

require 'rainbow'
require 'consyncful/item_mapper'
require 'consyncful/stats'
require 'hooks'

module Consyncful
  class Sync
    include Mongoid::Document
    include Hooks

    define_hook :before_run
    define_hook :after_run

    DEFAULT_LOCALE = 'en-NZ'

    field :next_url
    field :last_run_at, type: DateTime

    def self.latest
      last || new
    end

    def self.fresh
      destroy_all
      latest
    end

    def drop_stale
      stale = Base.where(:sync_id.ne => id, :sync_id.exists => true)
      puts Rainbow("Dropping #{stale.count} records that haven't been touched in this sync").red
      stale.destroy
    end

    def run
      run_hook :before_run
      stats = Consyncful::Stats.new
      load_all_models

      sync = start_sync

      changed_ids = sync_items(sync, stats)

      drop_stale

      self.next_url = sync.next_sync_url
      self.last_run_at = Time.current
      save
      stats.print_stats
      run_hook :after_run, changed_ids
    end

    private

    def load_all_models
      return unless defined? Rails

      Rails.application.eager_load!
    end

    def start_sync
      if next_url.present?
        puts Rainbow("Starting update, last update: #{last_run_at} (#{(Time.current - last_run_at).round(3)}s ago)").blue
        Consyncful.client.sync(next_url)
      else
        puts Rainbow('Starting full refresh').blue
        Consyncful.client.sync(initial: true)
      end
    end

    def sync_items(sync, stats)
      ids = []
      sync.each_page do |page|
        page.items.each do |item|
          ids << sync_item(ItemMapper.new(item), stats)
        end
      end
      ids
    end

    def sync_item(item, stats)
      puts Rainbow("syncing: #{item.id}").yellow
      if item.deletion?
        delete_model(item.id, stats)
      else
        create_or_update_model(item, stats)
      end
      item.id
    end

    def delete_model(id, stats)
      Base.find_by(id: id).destroy
      stats.record_deleted
    rescue Mongoid::Errors::DocumentNotFound
      puts Rainbow("Deleted record not found: #{id}").yellow
      nil
    end

    def create_or_update_model(item, stats)
      return if item.type.nil?

      instance = find_or_initialize_item(item)
      update_stats(instance, stats)

      reset_fields(instance)

      item.mapped_fields(DEFAULT_LOCALE).each do |field, value|
        instance[field] = value
      end

      instance[:sync_id] = id

      instance.save
    end

    def find_or_initialize_item(item)
      model_class(item.type).find_or_initialize_by(id: item.id)
    end

    def update_stats(instance, stats)
      if instance.persisted?
        stats.record_updated
      else
        stats.record_added
      end
    end

    def model_class(type)
      Base.model_map[type] || Base
    end

    def reset_fields(instance)
      instance.attributes.each do |field_name, _value|
        next if field_name.in? %w[_id _type]

        instance[field_name] = nil
      end
    end
  end
end
