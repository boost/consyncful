# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consyncful::Base do
  class self::TestContentfulType < Consyncful::Base
    contentful_model_name 'fooBar'

    references_many :foos
    references_one :bar

    indexes do
      index({ status: 1 }, background: true)
    end
  end

  class self::TestContentfulType2 < Consyncful::Base
    contentful_model_name 'Baz'
  end

  let(:test_klass_with_refs) { self.class::TestContentfulType }
  let(:test_klass) { self.class::TestContentfulType2 }

  describe '.contentful_model_name' do
    it 'creates a mapping of all contentful model names and their ruby model names' do
      expect(subject.model_map).to include('fooBar' => test_klass_with_refs)
      expect(subject.model_map).to include('Baz' => test_klass)
    end
  end

  describe '.references_many' do
    let(:referenced_items) { [test_klass.create, test_klass.create] }
    let(:referencing_item) { test_klass_with_refs.create(foos: referenced_items) }

    it 'creates a polymorphic has-and-belongs-to-many to other contentful models' do
      expect(referencing_item.foos).to eq referenced_items
    end

    it 'has an association extension that returns the items in the order they are appare in id array' do
      referencing_item.update(foo_ids: referencing_item.foo_ids.reverse)

      expect(referencing_item.foos.in_order).to eq referenced_items.reverse
    end
  end

  describe '.references_one' do
    let(:referenced_item) { test_klass.create }
    let(:referencing_item) { test_klass_with_refs.create(bar: referenced_item) }

    it 'creates a polymorphic belongs-to to other contentful models' do
      expect(referencing_item.bar).to eq referenced_item
    end
  end

  describe '.indexes' do
    it 'creates defines an index' do
      expect(test_klass.index_specifications.first).to be_a(Mongoid::Indexable::Specification)
    end

    it 'defines an index with the provided attributes' do
      expect(test_klass.index_specifications.first.fields).to include :status
      expect(test_klass.index_specifications.first.options[:background]).to eq true
    end

    it 'defines an index on the base class' do
      expect(Consyncful::Base.index_specifications.first.klass).to eq RSpec::ExampleGroups::ConsyncfulBase::TestContentfulType
    end
  end
end
