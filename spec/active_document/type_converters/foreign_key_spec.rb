# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::TypeConverters::ForeignKey do

  describe '.to_database_cast' do
    subject(:converted) { described_class.to_database_cast(object) }

    context 'when BSON::ObjectId' do
      let(:object) { BSON::ObjectId.new }

      it 'returns the same value' do
        is_expected.to eq(object)
      end

      it 'returns the same instance' do
        is_expected.to equal(object)
      end
    end

    describe 'when String' do

      context 'when the string is blank' do
        let(:object) { '' }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context 'when the string is a legal object id' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { object_id.to_s }

        it 'returns the object id' do
          is_expected.to eq(object_id)
        end
      end

      context 'when the string is not a legal object id' do
        let(:object) { 'testing' }

        it 'returns the string' do
          is_expected.to eq(object)
        end
      end
    end

    context 'when Array' do

      context 'when provided an array of strings' do
        let(:object_id) { BSON::ObjectId.new }
        let(:other) { 'blah' }
        let(:object) { [object_id.to_s, other] }

        it 'converts the convertible ones to object ids' do
          is_expected.to eq([object_id, other])
        end

        it 'returns the same instance' do
          is_expected.to equal(object)
        end
      end

      context 'when provided an array of object ids' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { [object_id] }

        it 'returns the array' do
          is_expected.to eq(object)
        end

        it 'returns the same instance' do
          is_expected.to equal(object)
        end
      end

      context 'when some values are nil' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { [object_id, nil] }

        it 'returns the array without the nils' do
          is_expected.to eq([object_id])
        end

        it 'returns the same instance' do
          is_expected.to equal(object)
        end
      end

      context 'when some values are empty strings' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { [object_id, ''] }

        it 'returns the array without the empty strings' do
          is_expected.to eq([object_id])
        end

        it 'returns the same instance' do
          is_expected.to equal(object)
        end
      end
    end

    context 'when Hash' do

      context 'when values have object id strings' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { { field: object_id.to_s } }

        it 'converts each value in the hash' do
          is_expected.to eq(field: object_id)
        end
      end

      context 'when values have object id strings wrapped in $oid' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { { field: { '$oid' => object_id.to_s } } }

        it 'converts each value in the hash' do
          is_expected.to eq(field: object_id)
        end
      end

      context 'when values have object ids' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { { field: object_id } }

        it 'converts each value in the hash' do
          is_expected.to eq(object)
        end
      end

      context 'when values have empty strings' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { { field: '' } }

        it 'converts the empty strings to nil' do
          is_expected.to eq(field: nil)
        end
      end

      context 'when values have nils' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { { field: '' } }

        it 'retains the nil values' do
          is_expected.to eq(field: nil)
        end
      end
    end

    context 'when Object' do
      let(:object) { Object.new }

      it 'returns the same value' do
        is_expected.to eq(object)
      end

      it 'returns the same instance' do
        is_expected.to equal(object)
      end
    end
  end

  describe '.to_query_cast' do
    subject(:converted) { described_class.to_query_cast(object) }

    context 'when BSON::ObjectId' do
      let(:object) { BSON::ObjectId.new }

      it 'returns the same value' do
        is_expected.to eq(object)
      end

      it 'returns the same instance' do
        is_expected.to equal(object)
      end
    end

    context 'when String' do

      context 'when the string is blank' do
        let(:object) { '' }

        it 'returns the empty string' do
          is_expected.to eq(object)
        end
      end

      context 'when the string is a legal object id' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { object_id.to_s }

        it 'returns the object id' do
          is_expected.to eq(object_id)
        end
      end

      context 'when the string is not a legal object id' do
        let(:object) { 'testing' }

        it 'returns the string' do
          is_expected.to eq(object)
        end
      end
    end

    context 'when Array' do

      context 'when provided an array of strings' do
        let(:object_id) { BSON::ObjectId.new }
        let(:other) { 'blah' }
        let(:object) { [object_id.to_s, other] }

        it 'converts the convertible ones to object ids' do
          is_expected.to eq([object_id, other])
        end

        it 'returns the same instance' do
          is_expected.to equal(object)
        end
      end

      context 'when provided an array of object ids' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { [object_id] }

        it 'returns the array' do
          is_expected.to eq(object)
        end

        it 'returns the same instance' do
          is_expected.to equal(object)
        end
      end

      context 'when some values are nil' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { [object_id, nil] }

        it 'returns the array with the nils' do
          is_expected.to eq(object)
        end

        it 'returns the same instance' do
          is_expected.to equal(object)
        end
      end

      context 'when some values are empty strings' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { [object_id, ''] }

        it 'returns the array with the empty strings' do
          is_expected.to eq(object)
        end

        it 'returns the same instance' do
          is_expected.to equal(object)
        end
      end
    end

    context 'when Hash' do

      context 'when values have object id strings' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { { field: object_id.to_s } }

        it 'converts each value in the hash' do
          is_expected.to eq(field: object_id)
        end
      end

      context 'when values have object id strings wrapped in $oid' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { { field: { '$oid' => object_id.to_s } } }

        it 'converts each value in the hash' do
          is_expected.to eq(field: object_id)
        end
      end

      context 'when values have object ids' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { { field: object_id } }

        it 'converts each value in the hash' do
          is_expected.to eq(object)
        end
      end

      context 'when values have empty strings' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { { field: '' } }

        it 'retains the empty string values' do
          is_expected.to eq(object)
        end
      end

      context 'when values have nils' do
        let(:object_id) { BSON::ObjectId.new }
        let(:object) { { field: nil } }

        it 'retains the nil values' do
          is_expected.to eq(object)
        end
      end
    end

    context 'when Object' do
      let(:object) { Object.new }

      it 'returns the same value' do
        is_expected.to eq(object)
      end

      it 'returns the same instance' do
        is_expected.to equal(object)
      end
    end
  end

  describe '.to_ruby_cast' do
    it 'is aliased to .to_database_cast' do
      expect(described_class.method(:to_ruby_cast)).to eq(described_class.method(:to_database_cast))
    end
  end
end
