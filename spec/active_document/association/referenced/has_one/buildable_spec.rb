# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Association::Referenced::Association do

  let(:base_id) { BSON::ObjectId.new }

  let(:base) do
    double(_id: base_id, new_record?: false)
  end

  describe '#build' do

    let(:document) do
      association.build(base, object)
    end

    let(:options) do
      {}
    end

    let(:association) do
      ActiveDocument::Association::Referenced::Association.new(Person, :account, :has_one, options)
    end

    context 'when provided an id' do

      let!(:account) do
        # For has_one, FK is on Account (person_id), create with base_id
        Account.create!(person_id: base_id, name: 'banking', balance: 200)
      end

      let(:object) do
        BSON::ObjectId.new
      end

      before do
        # has_one queries using base._id (base_id)
        expect_any_instance_of(ActiveDocument::Criteria).to receive(:where).with(association.foreign_key => base_id).and_call_original
      end

      it 'sets the document' do
        expect(document).to eq(account)
      end
    end

    context 'when scope is specified' do

      let!(:account) do
        Account.create!(person_id: base_id, name: 'banking', balance: 200)
      end

      let(:object) do
        BSON::ObjectId.new
      end

      let(:options) do
        {
          scope: -> { gt(balance: 100) }
        }
      end

      before do
        expect_any_instance_of(ActiveDocument::Criteria).to receive(:where).with(association.foreign_key => base_id).and_call_original
        expect_any_instance_of(ActiveDocument::Criteria).to receive(:gt).with(balance: 100).and_call_original
      end

      context 'when document satisfies scope' do

        it 'sets the document' do
          expect(document).to eq(account)
        end
      end

      context 'when document does not satisfy scope' do

        let!(:account) do
          Account.create!(person_id: base_id, name: 'banking', balance: 50)
        end

        it 'returns nil' do
          expect(document).to be_nil
        end
      end
    end

    context 'when provided a object' do

      let(:object) do
        Account.new
      end

      it 'returns the object' do
        expect(document).to eq(object)
      end

      context 'when the object is already associated with another object' do

        let(:original_person) do
          Person.new
        end

        let(:new_person) do
          Person.new
        end

        let(:object) do
          Account.new(person: original_person)
        end

        # In v2, binding happens when setting the association, not during build.
        # Test the normal flow through the setter instead of direct build call.
        before do
          new_person.account = object
        end

        it 'clears the object of its previous association' do
          expect(original_person.account).to be_nil
        end

        it 'sets the object on the new parent' do
          expect(new_person.account).to eq(object)
        end
      end
    end

    context 'when the document is not found' do

      let(:object) do
        BSON::ObjectId.new
      end

      it 'returns nil' do
        expect(document).to be_nil
      end
    end

    context 'when the document is persisted' do

      let(:person) do
        Person.create!
      end

      let!(:game) do
        Game.create!(person: person)
      end

      it 'returns the document' do
        expect(person.game).to eq(game)
      end
    end

    context 'when the document have a non standard pk' do

      let(:person) do
        Person.create!
      end

      let!(:cat) do
        Cat.create!(person: person)
      end

      it 'returns the document' do
        expect(person.cat).to eq(cat)
      end
    end
  end
end
