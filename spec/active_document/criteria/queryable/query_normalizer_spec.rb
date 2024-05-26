# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Criteria::Queryable::QueryNormalizer do

  describe '.normalize_expr' do
    subject(:normalized) do
      described_class.normalize_expr(condition, negating: negating)
    end

    let(:negating) do
      false
    end

    context 'when simple keys' do
      let(:condition) do
        { a: 1 }
      end

      it { is_expected.to eq({ 'a' => 1 }) }

      context 'when negating' do
        let(:negating) { true }

        it { is_expected.to eq({ 'a' => { '$ne' => 1 } }) }
      end
    end

    context 'when Hash' do
      let(:condition) do
        { 'age' => { '$gt' => 42 } }
      end

      it { is_expected.to eq(condition) }

      context 'when negating' do
        let(:negating) { true }

        it { is_expected.to eq({ 'age' => { '$not' => { '$gt' => 42 } } }) }
      end
    end

    context 'when multiple Hash keys on the same field' do
      let(:condition) do
        { 'age' => { '$gt' => 42, '$lt' => 50 } }
      end

      it { is_expected.to eq(condition) }

      context 'when negating' do
        let(:negating) { true }

        it { is_expected.to eq({ 'age' => { '$not' => { '$gt' => 42, '$lt' => 50 } } }) }
      end
    end

    [42, 'infinite', [nil]].each do |value|
      context "when mixed with equality value #{value}" do
        let(:condition) do
          { 'age' => { '$eq' => value, '$lt' => 50 } }
        end

        it { is_expected.to eq(condition) }

        context 'when negating' do
          let(:negating) { true }

          it { is_expected.to eq({ 'age' => { '$not' => { '$eq' => value, '$lt' => 50 } } }) }
        end
      end
    end

    [/42/, BSON::Regexp::Raw.new('42')].each do |value|
      context "when mixed with regular expression value #{value}" do
        let(:condition) do
          { 'age' => { '$regex' => value, '$lt' => 50 } }
        end

        it { is_expected.to eq(condition) }

        context 'when negating' do
          let(:negating) { true }

          it { is_expected.to eq({ 'age' => { '$not' => { '$regex' => value, '$lt' => 50 } } }) }
        end
      end
    end

    context 'when field => value' do
      shared_examples_for 'expands' do
        it 'expands' do
          is_expected.to eq({ 'foo' => 'bar' })
        end

        context 'when negating' do
          let(:negating) { true }

          it 'expands' do
            is_expected.to eq({ 'foo' => { '$ne' => 'bar' } })
          end
        end
      end

      context 'when string key' do
        let(:condition) do
          { 'foo' => 'bar' }
        end

        it_behaves_like 'expands'
      end

      context 'when symbol key' do
        let(:condition) do
          { foo: 'bar' }
        end

        it_behaves_like 'expands'
      end
    end

    context 'when operator expression' do
      let(:condition) do
        { 'foo' => { '$gt' => 'bar' } }
      end

      it 'expands' do
        is_expected.to eq(condition)
      end
    end

    context 'when field => operator value expression' do
      shared_examples_for 'expands' do

        it 'expands' do
          is_expected.to eq({ 'foo' => { '$in' => ['bar'] } })
        end
      end

      context 'when string operator key' do
        let(:condition) do
          { foo: { '$in' => %w[bar] } }
        end

        it_behaves_like 'expands'
      end

      context 'when symbol operator key' do
        let(:condition) do
          { foo: { '$in': %w[bar] } }
        end

        it_behaves_like 'expands'
      end
    end
  end

  describe '.to_array' do
    subject { described_class.send(:to_array, object) }

    context 'when Array' do
      let(:object) do
        [4, { foo: :bar }]
      end

      it { is_expected.to eq(object) }
    end

    context 'when Range' do
      let(:object) do
        1..3
      end

      it { is_expected.to eq([1, 2, 3]) }
    end

    context 'when other Object' do
      let(:object) do
        'Foobar'
      end

      it { is_expected.to eq(['Foobar']) }
    end
  end

  describe '.expand_condition_to_array_values' do

    shared_examples_for 'expands' do
      subject(:expanded) do
        described_class.expand_condition_to_array_values(criterion)
      end

      it 'expands' do
        is_expected.to eq(expected)
      end

      context 'when input is frozen' do
        before do
          criterion.freeze
        end

        it 'expands' do
          is_expected.to eq(expected)
        end
      end

      it 'does not modify input' do
        criterion_copy = criterion.dup.freeze
        is_expected.to eq(expected)
        expect(criterion).to eq(criterion_copy)
      end
    end

    context 'when Hash with literal value' do
      let(:criterion) do
        { foo: 4 }
      end

      let(:expected) do
        { foo: [4] }
      end

      it_behaves_like 'expands'
    end

    context 'when Hash with Range value' do
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
