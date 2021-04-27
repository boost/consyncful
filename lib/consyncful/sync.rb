# frozen_string_literal: true

require 'rainbow'
require 'consyncful/item_mapper'
require 'consyncful/persisted_item'
require 'consyncful/stats'
require 'hooks'

module Consyncful
  ##
  # A mongoid model that stores the state of a syncronisation feed. Stores the
  # next URL provided by Contentfuls Sync API.
  #
  # Sync's are affectivly singletons,
  # there should only ever be one in the database
  #
  # Is also the entrypoint of a Syncronization run
  class Sync
    include Mongoid::Document
    include Hooks

    store_in client: -> { Consyncful.configuration.mongo_client }

    define_hook :before_run
    define_hook :after_run

    field :next_url
    field :last_run_at, type: DateTime

    def self.latest
      last || new
    end

    ##
    # Delete the previous sync chains from database and create a fresh one.
    # Used to completely resync all items from Contentful.
    def self.fresh
      destroy_all
      latest
    end

    ##
    # Makes sure that the database contains only records that have been provided
    # during this chain of syncronisation.
    def drop_stale
      stale = Base.where(:sync_id.ne => id, :sync_id.exists => true)
      puts Rainbow("Dropping #{stale.count} records that haven't been touched in this sync").red
      stale.destroy
    end

    ##
    # Entry point to a syncronization run. Is responsible for updating Sync state
    def run
      run_hook :before_run

      stats = Consyncful::Stats.new
      load_all_models

      sync = start_sync

      changed_ids = sync_items(sync, stats)

      drop_stale

      update_run(sync.next_sync_url)
      stats.print_stats

      run_hook :after_run, changed_ids
    end

    private

    def load_all_models
      return unless defined? Rails

      Rails.application.eager_load!
    end

    def update_run(next_url)
      self.next_url = next_url
      self.last_run_at = Time.current
      save
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
      PersistedItem.new(item, id, stats).persist
      item.id
    end
  end
end
