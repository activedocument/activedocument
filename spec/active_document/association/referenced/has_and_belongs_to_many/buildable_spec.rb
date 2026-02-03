# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Association::Referenced::Association do

  # For belongs_to_many, base needs to respond to the foreign key getter (preference_ids)
  let(:base_preference_ids) { [] }

  let(:base) do
    double(preference_ids: base_preference_ids)
  end

  let(:options) do
    {}
  end

  describe '#build' do

    let(:documents) do
      association.build(base, object)
    end

    let(:association) do
      ActiveDocument::Association::Referenced::Association.new(Person, :preferences, :belongs_to_many, options)
    end

    context 'when provided ids' do

      let(:object_id) do
        BSON::ObjectId.new
      end

      # For belongs_to_many, the IDs come from base.preference_ids
      let(:base_preference_ids) { [object_id] }

      let(:object) do
        [object_id]
      end

      let(:criteria) do
        Preference.all_of('_id' => { '$in' => base_preference_ids })
      end

      it 'returns the criteria' do
        expect(documents).to eq(criteria)
      end
    end

    context 'when order specified' do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:options) do
        {
          order: { rating: :desc }
        }
      end

      let(:base_preference_ids) { [object_id] }

      let(:object) do
        [object_id]
      end

      let(:criteria) do
        Preference.all_of('_id' => { '$in' => base_preference_ids }).order_by(options[:order])
      end

      it 'returns the criteria' do
        expect(documents).to eq(criteria)
      end
    end

    context 'when scope is specified' do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:options) do
        {
          scope: -> { where(rating: 3) }
        }
      end

      let(:base_preference_ids) { [object_id] }

      let(:object) do
        [object_id]
      end

      let(:criteria) do
        Preference.all_of('_id' => { '$in' => base_preference_ids }).where(rating: 3)
      end

      it 'returns the criteria' do
        expect(documents).to eq(criteria)
      end
    end

    context 'when provided a object' do

      context 'when the object is not nil' do

        let(:object) do
          [Post.new]
        end

        it 'returns the objects' do
          expect(documents).to eq(object)
        end
      end

      context 'when the object is nil' do

        let(:object) do
          nil
        end

        # For belongs_to_many with nil object, criteria_by_id_list returns
        # an $in query on the base's (empty) FK array
        let(:criteria) do
          Preference.all_of('_id' => { '$in' => [] })
        end

        it 'a criteria object' do
          expect(documents).to eq(criteria)
        end
      end

      context 'when the object is an empty array' do
        let(:object) do
          []
        end

        let(:criteria) do
          Preference.none
        end

        it 'returns the objects' do
          expect(documents).to eq(object)
        end

        it 'doesnt execute the query' do
          expect_query(0) do
            expect(documents).to eq(object)
          end
        end
      end
    end

    context 'when no documents found in the database' do

      context 'when the ids are empty' do

        it 'returns an empty array' do
          expect(Person.new.preferences).to be_empty
        end
      end

      context 'when the ids are incorrect' do

        let(:person) do
          Person.create!
        end

        before do
          person.preference_ids = [BSON::ObjectId.new]
        end

        it 'returns an empty array' do
          expect(person.preferences).to be_empty
        end
      end
    end
  end
end
