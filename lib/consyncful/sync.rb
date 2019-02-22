# frozen_string_literal: true

require 'term/ansicolor'
require 'consyncful/item_mapper'
require 'consyncful/stats'

class String
  include Term::ANSIColor
end

module Consyncful
  class Sync
    include Mongoid::Document
    # include ActionView::Helpers::DateHelper

    DEFAULT_LOCALE = 'en-NZ'

    field :next_url
    field :last_run_at, type: DateTime

    def self.latest
      last || new
    end

    def self.reset
      destroy_all
      Base.destroy_all
    end

    def self.fresh
      reset
      latest
    end

    def run
      stats = Consyncful::Stats.new
      # Rails.application.eager_load! # todo
      sync = start_sync

      sync_items(sync, stats)

      self.next_url = sync.next_sync_url
      self.last_run_at = Time.current
      save
      stats.print_stats
    end

    private

    def start_sync
      if next_url.present?
        puts "Starting update, last update: #{last_run_at} (#{Time.current - last_run_at}s ago)".blue
        Consyncful.client.sync(next_url)
      else
        puts 'Starting full refresh'.blue
        Consyncful.client.sync(initial: true)
      end
    end

    def sync_items(sync, stats)
      sync.each_page do |page|
        page.items.each do |item|
          sync_item(ItemMapper.new(item), stats)
        end
      end
    end

    def sync_item(item, stats)
      puts "syncing: #{item.id}".yellow
      if item.deletion?
        delete_model(item.id, stats)
      else
        create_or_update_model(item, stats)
      end
    end

    def delete_model(id, stats)
      Base.find_by(id: id).destroy
      stats.record_deleted
    rescue Mongoid::Errors::DocumentNotFound
      puts "Deleted record not found: #{id}".yellow
      nil
    end

    def create_or_update_model(item, stats)
      return if item.type.nil?

      instance = find_or_initialize_item(item)
      update_stats(instance, stats)

      item.mapped_fields(DEFAULT_LOCALE).each do |field, value|
        instance[field] = value
      end

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
  end
end
