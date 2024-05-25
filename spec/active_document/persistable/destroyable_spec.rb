# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Persistable::Destroyable do

  describe '#destroy' do

    let!(:person) do
      Person.create!
    end

    context 'when destroying a readonly document' do
      let(:from_db) do
        Person.first.tap(&:readonly!)
      end

      it 'raises an error' do
        expect(from_db.readonly?).to be true
        expect do
          from_db.destroy
        end.to raise_error(ActiveDocument::Errors::ReadonlyDocument)
      end
    end

    context 'when destroying a document that was not saved' do
      let(:unsaved_person) { Person.new(id: person.id) }

      before do
        unsaved_person.destroy
      end

      it 'deletes the matching document from the database' do
        expect do
          person.reload
        end.to raise_error(ActiveDocument::Errors::DocumentNotFound, /Document\(s\) not found for class Person with id\(s\)/)
      end
    end

    context 'when destroying a root document' do

      let!(:destroyed) do
        person.destroy
      end

      it 'destroys the document from the collection' do
        expect do
          Person.find(person.id)
        end.to raise_error(ActiveDocument::Errors::DocumentNotFound, /Document\(s\) not found for class Person with id\(s\)/)
      end

      it 'returns true' do
        expect(destroyed).to be true
      end

      it 'resets the flagged for destroy flag' do
        expect(person).to_not be_flagged_for_destroy
      end

      context 'when :persist option false' do

        let!(:destroyed) do
          person.destroy(persist: false)
        end

        it 'does not destroy the document from the collection' do
          expect(Person.find(person.id)).to eq person
        end

        it 'returns true' do
          expect(destroyed).to be true
        end

        it 'does not set the flagged for destroy flag' do
          expect(person).to_not be_flagged_for_destroy
        end
      end
    end

    context 'when destroying an embedded document' do

      let(:address) do
        person.addresses.build(street: 'Bond Street')
      end

      context 'when the document is not yet saved' do

        before do
          address.destroy
        end

        it 'removes the document from the parent' do
          expect(person.addresses).to be_empty
        end

        it 'removes the attributes from the parent' do
          expect(person.raw_attributes['addresses']).to be_nil
        end

        it 'resets the flagged for destroy flag' do
          expect(address).to_not be_flagged_for_destroy
        end
      end

      context 'when the document has been saved' do

        before do
          address.save!
          address.destroy
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it 'removes the object from the parent' do
          expect(person.addresses).to be_empty
        end

        it 'removes the object from the database' do
          expect(from_db.addresses).to be_empty
        end
      end

      context 'when :persist option false' do

        before do
          address.save!
          address.destroy(persist: false)
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it 'does not remove the object from the parent' do
          expect(person.addresses).to eq [address]
          expect(person.addresses.first).to_not be_flagged_for_destroy
        end

        it 'does not remove the object from the database' do
          expect(from_db.addresses).to eq [address]
          expect(from_db.addresses.first).to_not be_flagged_for_destroy
        end
      end

      context 'when :suppress option true' do

        before do
          address.save!
          address.destroy(suppress: true)
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it 'does not remove the object from the parent' do
          expect(person.addresses).to eq [address]
          expect(person.addresses.first).to_not be_flagged_for_destroy
        end

        it 'removes the object from the database' do
          expect(from_db.addresses).to be_empty
        end
      end

      context 'when destroying from a list of embedded documents' do

        context 'when the embedded documents list is reversed in memory' do

          let(:word) do
            Word.create!(name: 'driver')
          end

          let(:from_db) do
            Word.find(word.id)
          end

          before do
            word.definitions.find_or_create_by(description: 'database connector')
            word.definitions.find_or_create_by(description: 'chauffeur')
            word.definitions = word.definitions.reverse
            word.definitions.last.destroy
          end

          it 'removes the embedded document in memory' do
            expect(word.definitions.size).to eq(1)
          end

          it 'removes the embedded document in the database' do
            expect(from_db.definitions.size).to eq(1)
          end
        end
      end
    end

    context 'when destroying deeply embedded documents' do

      context 'when the document has been saved' do

        let(:address) do
          person.addresses.create!(street: 'Bond Street')
        end

        let(:location) do
          address.locations.create!(name: 'Home')
        end

        let(:from_db) do
          Person.find(person.id)
        end

        before do
          location.destroy
        end

        it 'removes the object from the parent and database' do
          expect(from_db.addresses.first.locations).to be_empty
        end

        it 'resets the flagged for destroy flag' do
          expect(location).to_not be_flagged_for_destroy
        end
      end
    end

    context 'when there are dependent documents' do
      context 'has_one' do

        context 'dependent: :destroy' do
          let!(:parent) do
            Hole.create!(bolt: Bolt.create!)
          end

          it 'destroys dependent documents' do
            expect(Bolt.count).to eq(1)
            parent.destroy
            expect(Bolt.count).to eq(0)
          end
        end

        context 'dependent: :destroy_all' do
          let!(:parent) do
            Hole.create!(threadlocker: Threadlocker.create!)
          end

          it 'deletes dependent documents' do
            expect(Threadlocker.count).to eq(1)
            parent.destroy
            expect(Threadlocker.count).to eq(0)
          end
        end

        context 'dependent: :restrict_with_exception' do
          let!(:parent) do
            Hole.create!(sealer: Sealer.create!)
          end

          it 'raises an exception' do
            expect(Sealer.count).to eq(1)
            expect { parent.destroy }.to raise_error(ActiveDocument::Errors::DeleteRestriction)
            expect(Sealer.count).to eq(1)
          end
        end
      end

      context 'has_many' do

        context 'dependent: :destroy' do
          let!(:parent) do
            Hole.create!(nuts: [Nut.create!])
          end

          it 'destroys dependent documents' do
            expect(Nut.count).to eq(1)
            parent.destroy
            expect(Nut.count).to eq(0)
          end
        end

        context 'dependent: :destroy_all' do
          let!(:parent) do
            Hole.create!(washers: [Washer.create!])
          end

          it 'deletes dependent documents' do
            expect(Washer.count).to eq(1)
            parent.destroy
            expect(Washer.count).to eq(0)
          end
        end

        context 'dependent: :restrict_with_exception' do
          let!(:parent) do
            Hole.create!(spacers: [Spacer.create!])
          end

          it 'raises an exception' do
            expect(Spacer.count).to eq(1)
            expect { parent.destroy }.to raise_error(ActiveDocument::Errors::DeleteRestriction)
            expect(Spacer.count).to eq(1)
          end
        end
      end
    end
  end

  describe '#destroy!' do

    let(:person) do
      Person.create!
    end

    context 'when no validation callback returns false' do

      it 'returns true' do
        expect(person.destroy!).to be(true)
      end
    end

    context 'when a validation callback returns false' do

      let(:album) do
        Album.create!
      end

      before do
        Album.before_destroy(:set_parent_name_fail)
      end

      after do
        Album.reset_callbacks(:destroy)
      end

      it 'raises an exception' do
        expect do
          album.destroy!
        end.to raise_error(ActiveDocument::Errors::DocumentNotDestroyed)
      end
    end

    context 'when destroying a document that was not saved' do
      let(:unsaved_person) { Person.new(id: person.id) }

      before do
        unsaved_person.destroy!
      end

      it 'deletes the matching document from the database' do
        expect { person.reload }.to raise_error(ActiveDocument::Errors::DocumentNotFound, /Document\(s\) not found for class Person with id\(s\)/)
      end
    end

    context 'when destroying a root document' do

      let!(:destroyed) do
        person.destroy!
      end

      it 'destroys the document from the collection' do
        expect do
          Person.find(person.id)
        end.to raise_error(ActiveDocument::Errors::DocumentNotFound, /Document\(s\) not found for class Person with id\(s\)/)
      end

      it 'returns true' do
        expect(destroyed).to be true
      end

      it 'resets the flagged for destroy flag' do
        expect(person).to_not be_flagged_for_destroy
      end

      context 'when :persist option false' do

        let!(:destroyed) do
          person.destroy!(persist: false)
        end

        it 'does not destroy the document from the collection' do
          expect(Person.find(person.id)).to eq person
        end

        it 'returns true' do
          expect(destroyed).to be true
        end

        it 'does not set the flagged for destroy flag' do
          expect(person).to_not be_flagged_for_destroy
        end
      end
    end

    context 'when destroying an embedded document' do

      let(:address) do
        person.addresses.build(street: 'Bond Street')
      end

      context 'when the document is not yet saved' do

        before do
          address.destroy!
        end

        it 'removes the document from the parent' do
          expect(person.addresses).to be_empty
        end

        it 'removes the attributes from the parent' do
          expect(person.raw_attributes['addresses']).to be_nil
        end

        it 'resets the flagged for destroy flag' do
          expect(address).to_not be_flagged_for_destroy
        end
      end

      context 'when the document has been saved' do

        before do
          address.save!
          address.destroy!
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it 'removes the object from the parent' do
          expect(person.addresses).to be_empty
        end

        it 'removes the object from the database' do
          expect(from_db.addresses).to be_empty
        end
      end

      context 'when :persist option false' do

        before do
          address.save!
          address.destroy!(persist: false)
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it 'does not remove the object from the parent' do
          expect(person.addresses).to eq [address]
          expect(person.addresses.first).to_not be_flagged_for_destroy
        end

        it 'does not remove the object from the database' do
          expect(from_db.addresses).to eq [address]
          expect(from_db.addresses.first).to_not be_flagged_for_destroy
        end
      end

      context 'when :suppress option true' do

        before do
          address.save!
          address.destroy!(suppress: true)
        end

        let(:from_db) do
          Person.find(person.id)
        end

        it 'does not remove the object from the parent' do
          expect(person.addresses).to eq [address]
          expect(person.addresses.first).to_not be_flagged_for_destroy
        end

        it 'removes the object from the database' do
          expect(from_db.addresses).to be_empty
        end
      end
    end
  end

  describe '#destroy_all' do

    let!(:person) do
      Person.create!(title: 'sir')
    end

    context 'when no conditions are provided' do

      let!(:removed) do
        Person.destroy_all
      end

      it 'removes all the documents' do
        expect(Person.count).to eq(0)
      end

      it 'returns the number of documents removed' do
        expect(removed).to eq(1)
      end
    end

    context 'when conditions are provided' do

      let!(:person_two) do
        Person.create!
      end

      context 'when no conditions attribute provided' do

        let!(:removed) do
          Person.destroy_all(title: 'sir')
        end

        it 'removes the matching documents' do
          expect(Person.count).to eq(1)
        end

        it 'returns the number of documents removed' do
          expect(removed).to eq(1)
        end
      end
    end

    context 'when the write concern is unacknowledged' do

      before do
        Person.create!(title: 'miss')
      end

      let!(:removed) do
        Person.with(write: { w: 0 }) { |klass| klass.destroy_all(title: 'sir') }
      end

      it 'removes the matching documents' do
        expect(Person.where(title: 'miss').count).to eq(1)
      end

      it 'returns 0' do
        expect(removed).to eq(0)
      end
    end

    context 'when destroying a list of embedded documents' do

      context 'when the embedded documents list is reversed in memory' do

        let(:word) do
          Word.create!(name: 'driver')
        end

        before do
          word.definitions.find_or_create_by(description: 'database connector')
          word.definitions.find_or_create_by(description: 'chauffeur')
          word.definitions = word.definitions.reverse
          word.definitions.destroy_all
        end

        it 'removes all embedded documents' do
          expect(word.definitions.size).to eq(0)
        end
      end
    end

    context 'when there are dependent documents' do
      context 'has_one' do

        context 'dependent: :destroy' do
          let!(:parent) do
            Hole.create!.tap do |hole|
              Bolt.create!(hole: hole)
            end
          end

          it 'destroys dependent documents' do
            expect(Bolt.count).to eq(1)
            Hole.destroy_all
            expect(Bolt.count).to eq(0)
          end
        end

        context 'dependent: :delete_all' do
          let!(:parent) do
            Hole.create!.tap do |hole|
              Threadlocker.create!(hole: hole)
            end
          end

          it 'deletes dependent documents' do
            expect(Threadlocker.count).to eq(1)
            Hole.destroy_all
            expect(Threadlocker.count).to eq(0)
          end
        end

        context 'dependent: :restrict_with_exception' do
          let!(:parent) do
            Hole.create!.tap do |hole|
              Sealer.create!(hole: hole)
            end
          end

          it 'raises an exception' do
            expect(Sealer.count).to eq(1)
            expect { Hole.destroy_all }.to raise_error(ActiveDocument::Errors::DeleteRestriction)
            expect(Sealer.count).to eq(1)
          end
        end
      end

      context 'has_many' do

        context 'dependent: :destroy' do
          let!(:parent) do
            Hole.create!(nuts: [Nut.create!])
          end

          it 'destroys dependent documents' do
            expect(Nut.count).to eq(1)
            Hole.destroy_all
            expect(Nut.count).to eq(0)
          end
        end

        context 'dependent: :delete_all' do
          let!(:parent) do
            Hole.create!(washers: [Washer.create!])
          end

          it 'deletes dependent documents' do
            expect(Washer.count).to eq(1)
            Hole.destroy_all
            expect(Washer.count).to eq(0)
          end
        end

        context 'dependent: :restrict_with_exception' do
          let!(:parent) do
            Hole.create!(spacers: [Spacer.create!])
          end

          it 'raises an exception' do
            expect(Spacer.count).to eq(1)
            expect { Hole.destroy_all }.to raise_error(ActiveDocument::Errors::DeleteRestriction)
            expect(Spacer.count).to eq(1)
          end
        end
      end
    end
  end
end