# frozen_string_literal: true

module Consyncful
  ##
  # Provides common functionality of Mongoid models created from contentful
  # entries
  class Base
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    cattr_accessor :model_map

    store_in collection: -> { Consyncful.configuration.mongo_collection },
             client: -> { Consyncful.configuration.mongo_client }

    def self.contentful_model_name(name)
      self.model_map ||= {}

      self.model_map[name] = self
    end

    # rubocop:disable Lint/NestedMethodDefinition
    def self.references_many(name)
      has_and_belongs_to_many name.to_sym, class_name: 'Consyncful::Base', inverse_of: nil do
        def in_order
          _target.to_a.sort_by do |reference|
            _base[foreign_key].index(reference.id)
          end
        end
      end
    end
    # rubocop:enable Lint/NestedMethodDefinition

    def self.references_one(name)
      belongs_to name.to_sym, optional: true, class_name: 'Consyncful::Base'
    end
  end
end
