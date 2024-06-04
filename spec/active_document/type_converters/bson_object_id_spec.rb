# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::TypeConverters::BsonObjectId do

  describe '.to_database_cast' do

    context 'when BSON::ObjectId' do
      it 'returns self' do
        expect(object_id.__mongoize_object_id__).to eq(object_id)
      end

      it 'returns the same instance' do
        expect(object_id.__mongoize_object_id__).to equal(object_id)
      end
    end

    describe 'when String' do

      context 'when the string is blank' do

        it 'returns nil' do
          expect(''.__mongoize_object_id__).to be_nil
        end
      end

      context 'when the string is a legal object id' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        it 'returns the object id' do
          expect(object_id.to_s.__mongoize_object_id__).to eq(object_id)
        end
      end

      context 'when the string is not a legal object id' do

        let(:string) do
          'testing'
        end

        it 'returns the string' do
          expect(string.__mongoize_object_id__).to eq(string)
        end
      end
    end

    context 'when Array' do

      context 'when provided an array of strings' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:other) do
          'blah'
        end

        let(:array) do
          [object_id.to_s, other]
        end

        let(:mongoized) do
          array.__mongoize_object_id__
        end

        it 'converts the convertible ones to object ids' do
          expect(mongoized).to eq([object_id, other])
        end

        it 'returns the same instance' do
          expect(mongoized).to equal(array)
        end
      end

      context 'when provided an array of object ids' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:array) do
          [object_id]
        end

        let(:mongoized) do
          array.__mongoize_object_id__
        end

        it 'returns the array' do
          expect(mongoized).to eq(array)
        end

        it 'returns the same instance' do
          expect(mongoized).to equal(array)
        end
      end

      context 'when some values are nil' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:array) do
          [object_id, nil]
        end

        let(:mongoized) do
          array.__mongoize_object_id__
        end

        it 'returns the array without the nils' do
          expect(mongoized).to eq([object_id])
        end

        it 'returns the same instance' do
          expect(mongoized).to equal(array)
        end
      end

      context 'when some values are empty strings' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:array) do
          [object_id, '']
        end

        let(:mongoized) do
          array.__mongoize_object_id__
        end

        it 'returns the array without the empty strings' do
          expect(mongoized).to eq([object_id])
        end

        it 'returns the same instance' do
          expect(mongoized).to equal(array)
        end
      end
    end

    context 'when Hash' do

      context 'when values have object id strings' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:hash) do
          { field: object_id.to_s }
        end

        let(:mongoized) do
          hash.__mongoize_object_id__
        end

        it 'converts each value in the hash' do
          expect(mongoized[:field]).to eq(object_id)
        end
      end

      context 'when values have object ids' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:hash) do
          { field: object_id }
        end

        let(:mongoized) do
          hash.__mongoize_object_id__
        end

        it 'converts each value in the hash' do
          expect(mongoized[:field]).to eq(object_id)
        end
      end

      context 'when values have empty strings' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:hash) do
          { field: '' }
        end

        let(:mongoized) do
          hash.__mongoize_object_id__
        end

        it 'converts the empty strings to nil' do
          expect(mongoized[:field]).to be_nil
        end
      end

      context 'when values have nils' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:hash) do
          { field: nil }
        end

        let(:mongoized) do
          hash.__mongoize_object_id__
        end

        it 'retains the nil values' do
          expect(mongoized[:field]).to be_nil
        end
      end
    end

    context 'when Object' do
      it 'returns self' do
        expect(object.__mongoize_object_id__).to eq(object)
      end
    end
  end

  describe '.to_query_cast' do

    context 'when BSON::ObjectId' do
      it 'returns self' do
        expect(object_id.__evolve_object_id__).to eq(object_id)
      end

      it 'returns the same instance' do
        expect(object_id.__evolve_object_id__).to equal(object_id)
      end
    end

    context 'when String' do

      context 'when the string is blank' do

        it 'returns the empty string' do
          expect(''.__evolve_object_id__).to be_empty
        end
      end

      context 'when the string is a legal object id' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        it 'returns the object id' do
          expect(object_id.to_s.__evolve_object_id__).to eq(object_id)
        end
      end

      context 'when the string is not a legal object id' do

        let(:string) do
          'testing'
        end

        it 'returns the string' do
          expect(string.__evolve_object_id__).to eq(string)
        end
      end
    end

    context 'when Array' do

      context 'when provided an array of strings' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:other) do
          'blah'
        end

        let(:array) do
          [object_id.to_s, other]
        end

        let(:evolved) do
          array.__evolve_object_id__
        end

        it 'converts the convertible ones to object ids' do
          expect(evolved).to eq([object_id, other])
        end

        it 'returns the same instance' do
          expect(evolved).to equal(array)
        end
      end

      context 'when provided an array of object ids' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:array) do
          [object_id]
        end

        let(:evolved) do
          array.__evolve_object_id__
        end

        it 'returns the array' do
          expect(evolved).to eq(array)
        end

        it 'returns the same instance' do
          expect(evolved).to equal(array)
        end
      end

      context 'when some values are nil' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:array) do
          [object_id, nil]
        end

        let(:evolved) do
          array.__evolve_object_id__
        end

        it 'returns the array with the nils' do
          expect(evolved).to eq([object_id, nil])
        end

        it 'returns the same instance' do
          expect(evolved).to equal(array)
        end
      end

      context 'when some values are empty strings' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:array) do
          [object_id, '']
        end

        let(:evolved) do
          array.__evolve_object_id__
        end

        it 'returns the array with the empty strings' do
          expect(evolved).to eq([object_id, ''])
        end

        it 'returns the same instance' do
          expect(evolved).to equal(array)
        end
      end
    end

    context 'when Hash' do

      context 'when values have object id strings' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:hash) do
          { field: object_id.to_s }
        end

        let(:evolved) do
          hash.__evolve_object_id__
        end

        it 'converts each value in the hash' do
          expect(evolved[:field]).to eq(object_id)
        end
      end

      context 'when values have object ids' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:hash) do
          { field: object_id }
        end

        let(:evolved) do
          hash.__evolve_object_id__
        end

        it 'converts each value in the hash' do
          expect(evolved[:field]).to eq(object_id)
        end
      end

      context 'when values have empty strings' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:hash) do
          { field: '' }
        end

        let(:evolved) do
          hash.__evolve_object_id__
        end

        it 'retains the empty string values' do
          expect(evolved[:field]).to be_empty
        end
      end

      context 'when values have nils' do

        let(:object_id) do
          BSON::ObjectId.new
        end

        let(:hash) do
          { field: nil }
        end

        let(:evolved) do
          hash.__evolve_object_id__
        end

        it 'retains the nil values' do
          expect(evolved[:field]).to be_nil
        end
      end
    end

    context 'when Object' do
      it 'returns self' do
        expect(object.__evolve_object_id__).to eq(object)
      end
    end
  end

  describe '.to_ruby_cast' do
    # TODO
  end
end
