# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Criteria::Queryable::Mergeable do

  let(:query) do
    ActiveDocument::Query.new
  end

  describe '#intersect' do

    before do
      query.intersect
    end

    it 'sets the strategy to intersect' do
      expect(query.strategy).to eq(:__intersect__)
    end
  end

  describe '#override' do

    before do
      query.override
    end

    it 'sets the strategy to override' do
      expect(query.strategy).to eq(:__override__)
    end
  end

  describe '#union' do

    before do
      query.union
    end

    it 'sets the strategy to union' do
      expect(query.strategy).to eq(:__union__)
    end
  end

  describe '#_active_document_expand_keys' do
    let(:expanded) do
      query.send(:_active_document_expand_keys, condition)
    end

    it 'expands simple keys' do
      expect(query.send(:_active_document_expand_keys, { a: 1 })).to eq({ 'a' => 1 })
    end

    it 'expands Hash' do
      expected = { 'age' => { '$gt' => 42 } }
      expect(query.send(:_active_document_expand_keys, expected)).to eq({ 'age' => { '$gt' => 42 } })
    end

    it 'expands multiple Hash keys on the same field' do
      expected = { 'age' => { '$gt' => 42, '$lt' => 50 } }
      expect(query.send(:_active_document_expand_keys, expected)).to eq(expected)
    end

    context 'given implicit equality and Hash on the same field' do
      [42, 'infinite', [nil]].each do |value|
        context "for non-regular expression value #{value}" do
          context 'implicit equality then Hash' do
            it 'expands implicit equality with $eq and combines with Hash' do
              expected = { 'age' => { '$eq' => value, '$lt' => 50 } }
              expect(query.send(:_active_document_expand_keys, expected)).to eq(expected)
            end
          end

          context 'symbol operator then implicit equality' do
            it 'expands implicit equality with $eq and combines with Hash' do
              expected = { 'age' => { '$gt' => 42, '$eq' => value } }
              expect(query.send(:_active_document_expand_keys, expected)).to eq(expected)
            end
          end
        end
      end
    end

    context 'given implicit equality with Regexp argument and Hash on the same field' do
      [/42/, BSON::Regexp::Raw.new('42')].each do |value|
        context "for regular expression value #{value}" do
          context 'implicit equality then Hash' do
            it 'expands implicit equality with $eq and combines with Hash' do
              expected = { 'age' => { '$regex' => value, '$lt' => 50 } }
              expect(query.send(:_active_document_expand_keys, expected)).to eq(expected)
            end
          end

          context 'Key instance then implicit equality' do
            it 'expands implicit equality with $eq and combines with Hash' do
              expected = { 'age' => { '$gt' => 50, '$regex' => value } }
              expect(query.send(:_active_document_expand_keys, expected)).to eq(expected)
            end
          end
        end
      end
    end

    context 'field name => value' do
      shared_examples_for 'expands' do

        it 'expands' do
          expect(expanded).to eq({ 'foo' => 'bar' })
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
        expect(expanded).to eq(condition)
      end
    end

    context 'operator => operator value expression' do
      shared_examples_for 'expands' do

        it 'expands' do
          expect(expanded).to eq({ 'foo' => { '$in' => ['bar'] } })
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
end
