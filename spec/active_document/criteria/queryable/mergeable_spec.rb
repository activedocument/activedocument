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
    let(:lt) do
      ActiveDocument::Criteria::Queryable::Key.new('age', :__override__, '$lt')
    end
    let(:gtp) do
      ActiveDocument::Criteria::Queryable::Key.new('age', :__override__, '$gt')
    end
    let(:gt) do
      ActiveDocument::Criteria::Queryable::Key.new('age', :__override__, '$gt')
    end

    it 'expands simple keys' do
      expect(query.send(:_active_document_expand_keys, { a: 1 })).to eq({ 'a' => 1 })
    end

    it 'expands Key instances' do
      expect(query.send(:_active_document_expand_keys, { gt => 42 })).to eq({ 'age' => { '$gt' => 42 } })
    end

    it 'expands multiple Key instances on the same field' do
      expected = { 'age' => { '$gt' => 42, '$lt' => 50 } }
      expect(query.send(:_active_document_expand_keys, { gt => 42, lt => 50 })).to eq(expected)
    end

    context 'given implicit equality and Key instance on the same field' do
      [42, 'infinite', [nil]].each do |value|
        context "for non-regular expression value #{value}" do
          context 'implicit equality then Key instance' do
            it 'expands implicit equality with $eq and combines with Key operator' do
              expected = { 'age' => { '$eq' => value, '$lt' => 50 } }
              expect(query.send(:_active_document_expand_keys, { 'age' => value, lt => 50 })).to eq(expected)
            end
          end

          context 'symbol operator then implicit equality' do
            it 'expands implicit equality with $eq and combines with Key operator' do
              expected = { 'age' => { '$gt' => 42, '$eq' => value } }
              expect(query.send(:_active_document_expand_keys, { gt => 42, 'age' => value })).to eq(expected)
            end
          end
        end
      end
    end

    context 'given implicit equality with Regexp argument and Key instance on the same field' do
      [/42/, BSON::Regexp::Raw.new('42')].each do |value|
        context "for regular expression value #{value}" do
          context 'implicit equality then Key instance' do
            it 'expands implicit equality with $eq and combines with Key operator' do
              expected = { 'age' => { '$regex' => value, '$lt' => 50 } }
              expect(query.send(:_active_document_expand_keys, { 'age' => value, lt => 50 })).to eq(expected)
            end
          end

          context 'Key instance then implicit equality' do
            it 'expands implicit equality with $eq and combines with Key operator' do
              expected = { 'age' => { '$gt' => 50, '$regex' => value } }
              expect(query.send(:_active_document_expand_keys, { gt => 50, 'age' => value })).to eq(expected)
            end
          end
        end
      end
    end

    it 'Ruby does not allow same symbol operator with different values' do
      expect({ gt => 42, gtp => 50 }).to eq({ gtp => 50 })
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
      let(:key) do
        ActiveDocument::Criteria::Queryable::Key.new(:foo, :__override__, '$gt')
      end

      let(:condition) do
        { key => 'bar' }
      end

      it 'expands' do
        expect(expanded).to eq({ 'foo' => { '$gt' => 'bar' } })
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
          { foo: { :$in => %w[bar] } }
        end

        it_behaves_like 'expands'
      end
    end
  end
end
