# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Criteria::Queryable::QueryNormalizer do

  describe '.normalize_expr' do
    let(:query) do
      ActiveDocument::Query.new
    end

    subject(:normalized) do
      described_class.normalize_expr(query, condition)
    end

    context 'when simple keys' do
      let(:condition) do
        { a: 1 }
      end

      it { is_expected.to eq({ 'a' => 1 }) }
    end

    context 'when Hash' do
      let(:condition) do
        { 'age' => { '$gt' => 42 } }
      end

      it { is_expected.to eq(condition) }
    end

    context 'when multiple Hash keys on the same field' do
      let(:condition) do
        { 'age' => { '$gt' => 42, '$lt' => 50 } }
      end

      it { is_expected.to eq(condition) }
    end

    context 'given implicit equality and Hash on the same field' do
      [42, 'infinite', [nil]].each do |value|
        context 'implicit equality then Hash' do
          let(:condition) do
            { 'age' => { '$eq' => value, '$lt' => 50 } }
          end

          it { is_expected.to eq(condition) }
        end
      end
    end

    context 'given implicit equality with Regexp argument and Hash on the same field' do
      [/42/, BSON::Regexp::Raw.new('42')].each do |value|
        context "for regular expression value #{value}" do
          context 'implicit equality then Hash' do
            it 'expands implicit equality with $eq and combines with Hash' do
              expected = { 'age' => { '$regex' => value, '$lt' => 50 } }
              expect(described_class.normalize_expr(query, expected)).to eq(expected)
            end
          end

          context 'Key instance then implicit equality' do
            it 'expands implicit equality with $eq and combines with Hash' do
              expected = { 'age' => { '$gt' => 50, '$regex' => value } }
              expect(described_class.normalize_expr(query, expected)).to eq(expected)
            end
          end
        end
      end
    end

    context 'field name => value' do
      shared_examples_for 'expands' do
        it 'expands' do
          is_expected.to eq({ 'foo' => 'bar' })
        end
      end

      context 'string key' do
        let(:condition) do
          { 'foo' => 'bar' }
        end

        it_behaves_like 'expands'
      end

      context 'symbol key' do
        let(:condition) do
          { foo: 'bar' }
        end

        it_behaves_like 'expands'
      end
    end

    context 'Key instance => value' do
      let(:condition) do
        { 'foo' => { '$gt' => 'bar' } }
      end

      it 'expands' do
        is_expected.to eq(condition)
      end
    end

    context 'operator => operator value expression' do
      shared_examples_for 'expands' do

        it 'expands' do
          is_expected.to eq({ 'foo' => { '$in' => ['bar'] } })
        end
      end

      context 'string key' do
        let(:condition) do
          { foo: { '$in' => %w[bar] } }
        end

        it_behaves_like 'expands'
      end

      context 'symbol key' do
        let(:condition) do
          { foo: { '$in': %w[bar] } }
        end

        it_behaves_like 'expands'
      end
    end
  end

  describe '.expr_part' do

    context 'when String' do
      subject { described_class.expr_part('field', value) }

      let(:value) { 10 }

      it 'returns the expression with the value' do
        is_expected.to eq({ 'field' => 10 })
      end

      context 'with a Regexp' do
        let(:value) { /test/ }

        it 'returns the expression with the value' do
          is_expected.to eq({ 'field' => /test/ })
        end
      end

      context 'with a BSON::Regexp::Raw' do
        let(:value) { BSON::Regexp::Raw.new('^[123]') }

        it 'returns the expression with the value' do
          is_expected.to eq({ 'field' => BSON::Regexp::Raw.new('^[123]') })
        end
      end

      context 'when negated' do
        subject { described_class.expr_part('field', value, true) }

        context 'with a Regexp' do
          let(:value) { /test/ }

          it 'returns the expression with the value negated' do
            is_expected.to eq({ 'field' => { '$not' => /test/ } })
          end
        end

        context 'with a BSON::Regexp::Raw' do
          let(:value) { BSON::Regexp::Raw.new('^[123]') }

          it 'returns the expression with the value' do
            is_expected.to eq({ 'field' => { '$not' => BSON::Regexp::Raw.new('^[123]') } })
          end
        end

        context 'with anything else' do
          let(:value) { 'test' }

          it 'returns the expression with the value negated' do
            is_expected.to eq({ 'field' => { '$ne' => 'test' } })
          end
        end
      end
    end

    context 'when Symbol' do
      subject { described_class.expr_part(:field, 10) }

      it 'returns the string with the value' do
        is_expected.to eq({ field: 10 })
      end

      context 'with a regexp' do
        subject { described_class.expr_part(:field, /test/) }

        it 'returns the symbol with the value' do
          is_expected.to eq({ field: /test/ })
        end
      end

      context 'when negated' do

        context 'with a regexp' do
          subject { described_class.expr_part(:field, /test/, true) }

          it 'returns the symbol with the value negated' do
            is_expected.to eq({ field: { '$not' => /test/ } })
          end
        end

        context 'with anything else' do
          subject { described_class.expr_part(:field, 'test', true) }

          it 'returns the symbol with the value negated' do
            is_expected.to eq({ field: { '$ne' => 'test' } })
          end
        end
      end
    end
  end

  describe '.expand_complex' do
    subject { described_class.expand_complex(object) }

    context 'when Array' do
      let(:object) do
        [{ test: { '$in' => ['value'] } }]
      end

      it 'expands all keys inside the array' do
        is_expected.to eq([{ 'test' => { '$in' => ['value'] } }])
      end
    end

    context 'when Hash' do
      let(:object) do
        {
          test1: {
            '$elemMatch' => {
              test2: {
                '$elemMatch' => {
                  test3: { '$in' => ['value1'] }
                }
              }
            }
          }
        }
      end

      let(:expected) do
        {
          'test1' => {
            '$elemMatch' => {
              'test2' => {
                '$elemMatch' => {
                  'test3' => { '$in' => ['value1'] }
                }
              }
            }
          }
        }
      end

      it 'expands the nested values' do
        is_expected.to eq(expected)
      end
    end

    context 'when other Object' do
      let(:object) do
        'Foobar'
      end

      it 'expands all keys inside the array' do
        is_expected.to eq('Foobar')
      end
    end
  end
end
