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

    def excluded_by_tag?
      return (Consyncful.configuration.content_tags & item_tag_ids).empty?      if Consyncful.configuration.content_tags.any?
      return (Consyncful.configuration.ignore_content_tags & item_tag_ids).any? if Consyncful.configuration.ignore_content_tags.any?

      false
    end

    def type
      case @item.type
      when 'Entry' then @item.content_type.id
      when 'Asset' then 'asset'
      end
    end

    def id
      @item.id
    end

    def mapped_fields(default_locale)
      fields = generic_fields

      fields.merge!(localized_fields(default_locale))
      fields.merge!(localized_asset_fields(default_locale)) if type == 'asset'
      fields.merge!(contentful_timestamps) if Consyncful.configuration.preserve_contentful_timestamps

      fields
    end

    private

    def item_tag_ids
      return [] if @item.nil?

      @item._metadata[:tags].map(&:id)
    end

    def generic_fields
      {
        created_at: @item.created_at,
        updated_at: @item.updated_at,
        revision: @item.revision,
        contentful_type: type,
        contentful_tags: @item._metadata[:tags].map(&:id),
        synced_at: Time.current
      }
    end

    def localized_fields(default_locale)
      fields = {}

      @item.fields_with_locales.each do |field, value_with_locales|
        value_with_locales.each do |locale_code, value|
          next if value.is_a? Contentful::File # assets are handeled below

          field_name = localized_field_name(field, locale_code, default_locale)
          field_name, value = mapped_field_entry_for(field_name, value)
          fields[field_name] = value
        end
      end

      fields
    end

    def localized_asset_fields(default_locale)
      fields = {}
      files_by_locale = @item.raw.dig('fields', 'file') || {}

      files_by_locale.each do |locale_code, details|
        field_name = localized_field_name('file', locale_code, default_locale)
        fields[field_name.to_sym] = details
      end

      fields
    end

    # Suffixes the field with the locale unless it's the default locale.
    def localized_field_name(field, locale_code, default_locale)
      return field if locale_code.to_s == default_locale.to_s

      "#{field}_#{locale_code.to_s.underscore}".to_sym
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

    def mapped_field_entry_for(field, value)
      if single_reference?(value)
        [ActiveSupport::Inflector.foreign_key(field).to_sym, value.id]
      elsif many_reference?(value)
        ids_field_name = "#{field.to_s.singularize}_ids" # fk field name
        [ids_field_name.to_sym, value.map(&:id)]
      else
        [field, value]
      end
    end

    def contentful_timestamps
      {
        contentful_created_at: @item.created_at,
        contentful_updated_at: @item.updated_at
      }
    end
  end
end
