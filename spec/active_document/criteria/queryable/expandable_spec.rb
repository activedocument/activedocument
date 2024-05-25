# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Criteria::Queryable::Expandable do

  let(:query) do
    ActiveDocument::Query.new
  end

  describe '#expand_condition_to_array_values' do
    shared_examples_for 'expands' do

      it 'expands' do
        expect(query.send(:expand_condition_to_array_values, criterion)).to eq(expected)
      end

      context 'when input is frozen' do
        before do
          criterion.freeze
        end

        it 'expands' do
          expect(query.send(:expand_condition_to_array_values, criterion)).to eq(expected)
        end
      end

      it 'does not modify input' do
        criterion_copy = criterion.dup.freeze

        expect(query.send(:expand_condition_to_array_values, criterion)).to eq(expected)

        expect(criterion).to eq(criterion_copy)
      end
    end

    context 'literal value' do
      let(:criterion) do
        { foo: 4 }
      end

      let(:expected) do
        { foo: [4] }
      end

      it_behaves_like 'expands'
    end

    context 'Range value' do
      let(:criterion) do
        { foo: 1..4 }
      end

      let(:expected) do
        { foo: [1, 2, 3, 4] }
      end

      it_behaves_like 'expands'
    end
  end
end