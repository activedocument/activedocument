# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Association::Referenced::HasOne::Binding do

  let(:person) do
    Person.new
  end

  let(:game) do
    Game.new
  end

  let(:association) do
    Person.relations['game']
  end

  describe '#bind_one' do

    let(:binding) do
      described_class.new(person, game, association)
    end

    context 'when the document is bindable' do

      before do
        expect(person).to_not receive(:save)
        expect(game).to_not receive(:save)
        binding.bind_one
      end

      it 'sets the inverse relation' do
        expect(game.person).to eq(person)
      end

      it 'sets the foreign key' do
        expect(game.person_id).to eq(person.id)
      end
    end

    context 'when the document is not bindable' do

      before do
        game.person = person
      end

      it 'does nothing' do
        expect(person).to_not receive(:game=)
        binding.bind_one
      end
    end
  end

  describe '#unbind_one' do

    let(:binding) do
      described_class.new(person, game, association)
    end

    context 'when the document is unbindable' do

      before do
        binding.bind_one
        expect(person).to_not receive(:delete)
        expect(game).to_not receive(:delete)
        binding.unbind_one
      end

      it 'removes the inverse relation' do
        expect(game.person).to be_nil
      end

      it 'removed the foreign key' do
        expect(game.person_id).to be_nil
      end
    end

    context 'when the document is not unbindable' do

      it 'does nothing' do
        expect(person).to_not receive(:game=)
        binding.unbind_one
      end
    end
  end

  context 'when binding frozen documents' do

    let(:person) do
      Person.new
    end

    context 'when the child is frozen' do

      let(:game) do
        Game.new.freeze
      end

      before do
        person.game = game
      end

      it 'does not set the foreign key' do
        expect(game.person_id).to be_nil
      end
    end
  end

  context 'when unbinding frozen documents' do

    let(:person) do
      Person.new
    end

    context 'when the child is frozen' do

      let(:game) do
        Game.new
      end

      before do
        person.game = game
        game.freeze
        person.game = nil
      end

      it 'does not unset the foreign key' do
        expect(game.person_id).to eq(person.id)
      end
    end
  end
end
