# frozen_string_literal: true

module Consyncful
  ##
  # Responsible for mapping an update received from Contentful's syncronisation API
  # into useful fields for Consyncful::PersistedItem to store in the database.
  class ItemMapper
    def initialize(item)
      @item = item
    end

    def deletion?
      @item.is_a?(Contentful::DeletedEntry) || @item.is_a?(Contentful::DeletedAsset)
    end

    def type
      if @item.type == 'Entry'
        @item.content_type.id
      elsif @item.type == 'Asset'
        'asset'
      end
    end

    def id
      @item.id
    end

    def mapped_fields(default_locale)
      fields = generic_fields

      fields.merge!(localized_fields(default_locale))
      fields.merge!(localized_asset_fields(default_locale)) if type == 'asset'

      fields
    end

    private

    def generic_fields
      fields = {}
      fields[:created_at] = @item.created_at
      fields[:updated_at] = @item.updated_at
      fields[:revision] = @item.revision
      fields[:contentful_type] = type
      fields[:synced_at] = Time.current
      fields
    end

    def localized_fields(default_locale)
      fields = {}

      @item.fields_with_locales.each do |field, value_with_locales|
        value_with_locales.each do |locale_code, value|
          next if value.is_a? Contentful::File # assets are handeled below
    
          fieldname = locale_code == default_locale.to_sym ? field : "#{field}_#{locale_code.to_s.underscore}".to_sym
          assign_field(fields, fieldname, value)
        end
      end

      fields
    end

    def localized_asset_fields(default_locale)
      fields = {}
      files_by_locale = @item.raw.dig('fields', 'file') || {}

      files_by_locale.each do |locale_code, details|
        fieldname = locale_code == default_locale ? 'file' : "file_#{locale_code.to_s.underscore}"
        fields[fieldname.to_sym] = details
      end

      fields
    end

    def reference_value?(value)
      single_reference?(value) || many_reference?(value)
    end

    def single_reference?(value)
      value.is_a?(Contentful::BaseResource)
    end

    def many_reference?(value)
      value.is_a?(Array) && single_reference?(value.first)
    end

    def assign_field(hash, field, value)
      if single_reference?(value)
        hash[ActiveSupport::Inflector.foreign_key(field).to_sym] = value.id
      elsif many_reference?(value)
        ids_field_name = field.to_s.singularize + '_ids' # fk field name
        hash[ids_field_name.to_sym] = value.map(&:id)
      else
        hash[field] = value
      end
    end
  end
end
