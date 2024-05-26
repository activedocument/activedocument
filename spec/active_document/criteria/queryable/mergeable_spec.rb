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
end
