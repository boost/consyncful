# frozen_string_literal: true

module Consyncful
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

    def mapped_fields(locale)
      fields = generic_fields

      @item.fields_with_locales.each do |field, value_with_locales|
        value = value_with_locales[locale.to_sym]
        next if value.is_a? Contentful::File # it is special

        assign_field(fields, field, value)
      end

      fields[:file] = raw_file(locale) if type == 'asset'

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

    def raw_file(locale)
      file_json = @item.raw.fetch('fields', {}).fetch('file', nil)
      file_json[locale]
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
