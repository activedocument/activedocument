# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Fields::FieldTypes do

  around do |example|
    described_class.instance_variable_set(:@mapping, described_class::DEFAULT_MAPPING.dup)
    example.run
    described_class.instance_variable_set(:@mapping, described_class::DEFAULT_MAPPING.dup)
  end

  describe '.get' do
    subject { described_class.get(type) }

    context 'when value is a default mapped symbol' do
      let(:type) { :float }

      it 'uses the default mapped type' do
        is_expected.to eq Float
      end
    end

    context 'when value is a default mapped string' do
      let(:type) { 'float' }

      it 'uses the default mapped type' do
        is_expected.to eq Float
      end
    end

    context 'when value is a custom mapped symbol' do
      before { described_class.define_type('number', Integer) }

      let(:type) { :number }

      it 'uses the custom mapped type' do
        is_expected.to eq Integer
      end
    end

    context 'when value is a custom mapped string' do
      before { described_class.define_type(:number, Float) }

      let(:type) { 'number' }

      it 'uses the custom mapped type' do
        is_expected.to eq Float
      end
    end

    context 'when value is an unmapped symbol' do
      let(:type) { :my_value }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when value is a unmapped string' do
      let(:type) { 'my_value' }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when value is a module' do
      let(:type) { String }

      it 'uses the module type' do
        is_expected.to eq String
      end

      context 'deprecation' do
        around do |example|
          old_types = described_class.instance_variable_get(:@warned_class_types)
          described_class.instance_variable_set(:@warned_class_types, [])
          example.run
          described_class.instance_variable_set(:@warned_class_types, old_types)
        end

        it 'warns deprecation for the class type once' do
          expect(Mongoid.logger).to receive(:warn).once.with(match(/\AUsing a Class \(String\)/))
          described_class.get(String)
          described_class.get(String)
          expect(Mongoid.logger).to receive(:warn).once.with(match(/\AUsing a Class \(Integer\)/))
          described_class.get(Integer)
          described_class.get(String)
          described_class.get(Integer)
        end
      end
    end

    context 'when value is the module Boolean' do
      let(:type) do
        stub_const('Boolean', Module.new)
        Boolean
      end

      it 'returns ActiveDocument::Boolean type' do
        is_expected.to eq ActiveDocument::Boolean
      end
    end

    context 'when value is nil' do
      let(:type) { nil }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '.define' do

    it 'can define a new type' do
      described_class.define_type(:my_string, String)
      expect(described_class.get(:my_string)).to eq String
    end

    it 'can override a default type' do
      described_class.define_type(:integer, String)
      expect(described_class.get(:integer)).to eq String
    end

    it 'does not alter the DEFAULT_MAPPING constant' do
      described_class.define_type(:integer, String)
      expect(described_class::DEFAULT_MAPPING[:integer]).to eq Integer
    end
  end

  describe '.delete' do

    it 'can delete a custom type' do
      described_class.define_type(:my_string, String)
      expect(described_class.get(:my_string)).to eq String
      described_class.delete('my_string')
      expect(described_class.get(:my_string)).to be_nil
    end

    it 'can delete a default type' do
      described_class.delete(:integer)
      expect(described_class.get(:integer)).to be_nil
    end

    it 'does not alter the DEFAULT_MAPPING constant' do
      described_class.delete(:integer)
      expect(described_class::DEFAULT_MAPPING[:integer]).to eq Integer
    end
  end

  describe '.mapping' do

    it 'returns the default mapping by default' do
      expect(described_class.mapping).to eq described_class::DEFAULT_MAPPING
    end

    it 'can add a type' do
      described_class.define_type(:my_string, String)
      expect(described_class.mapping[:my_string]).to eq(String)
    end

    it 'can delete a default type' do
      described_class.delete(:integer)
      expect(described_class.mapping).to_not have_key(:integer)
    end
  end
end
