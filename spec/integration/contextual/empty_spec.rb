# frozen_string_literal: true

require 'spec_helper'

describe 'Contextual classes when dealing with empty result set' do
  shared_examples 'behave as expected' do
    describe '#exists?' do
      it 'is false' do
        expect(context.exists?).to be false
      end
    end

    describe '#count' do
      it 'is 0' do
        expect(context.count).to eq(0)
      end
    end

    describe '#length' do
      it 'is 0' do
        expect(context.length).to eq(0)
      end
    end

    # #estimated_count only exists for Mongo

    describe '#distinct' do
      it 'is empty array' do
        expect(context.distinct(:foo)).to eq([])
      end
    end

    describe '#each' do
      context 'with block' do
        it 'does not invoke the block' do
          called = false
          context.each do
            called = true
          end
          expect(called).to be false
        end
      end

      context 'without block' do
        it 'returns Enumerable' do
          expect(context.each).to be_a(Enumerable)
        end

        it 'returns empty Enumerable' do
          expect(context.each.to_a).to eq([])
        end
      end
    end

    describe '#map' do
      context 'with block' do
        it 'does not invoke the block' do
          called = false
          context.map do
            called = true
          end
          expect(called).to be false
        end
      end

      context 'without block' do
        it 'returns empty array' do
          skip 'MONGOID-5148'

          expect(context.map(:field)).to eq([])
        end
      end
    end

    describe '#first' do
      it 'is nil' do
        expect(context.first).to be_nil
      end
    end

    describe '#find_first' do
      it 'is nil' do
        expect(context.find_first).to be_nil
      end
    end

    describe '#one' do
      it 'is nil' do
        expect(context.one).to be_nil
      end
    end

    describe '#last' do
      it 'is nil' do
        expect(context.last).to be_nil
      end
    end
  end

  let(:context) do
    context_cls.new(criteria)
  end

  before do
    # Create an object of the same class used in the Criteria instance
    # to verify we are using the Contextual classes.
    Mop.create!
  end

  context 'Mongo' do
    let(:context_cls) { ActiveDocument::Contextual::Mongo }

    let(:criteria) do
      Mop.all_of(Mop.where(a: 1), Mop.where(a: 2))
    end

    include_examples 'behave as expected'
  end

  context 'Memory' do
    let(:context_cls) { ActiveDocument::Contextual::Memory }

    let(:criteria) do
      Mop.all.tap do |criteria|
        criteria.documents = []
      end
    end

    include_examples 'behave as expected'
  end

  context 'None' do
    let(:context_cls) { ActiveDocument::Contextual::None }

    let(:criteria) do
      Mop.none
    end

    include_examples 'behave as expected'
  end
end
