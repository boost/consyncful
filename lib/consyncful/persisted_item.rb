# frozen_string_literal: true

module Consyncful
  # Takes a mapped item from contentful and applies it to the local storage.
  class PersistedItem
    DEFAULT_LOCALE = 'en-NZ'

    def initialize(item, sync_id, stats)
      @item = item
      @sync_id = sync_id
      @stats = stats
    end

    def persist
      puts Rainbow("syncing: #{@item.id}").yellow
      if @item.deletion?
        delete_model(@item.id, @stats)
      else
        create_or_update_model(@item, @sync_id, @stats)
      end
    end

    private

    def delete_model(id, stats)
      Base.find_by(id: id).destroy
      stats.record_deleted
    rescue Mongoid::Errors::DocumentNotFound
      puts Rainbow("Deleted record not found: #{id}").yellow
      nil
    end

    def create_or_update_model(item, sync_id, stats)
      return if item.type.nil?

      instance = find_or_initialize_item(item)
      update_stats(instance, stats)

      reset_fields(instance)

      item.mapped_fields(DEFAULT_LOCALE).each do |field, value|
        instance[field] = value
      end

      instance[:sync_id] = sync_id

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
