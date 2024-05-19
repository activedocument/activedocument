# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Contextual::Aggregable::None do

  before do
    Band.create!(name: 'Depeche Mode')
  end

  let(:context) do
    ActiveDocument::Contextual::None.new(Band.where(name: 'Depeche Mode'))
  end

  describe '#aggregates' do
    it 'returns fixed values' do
      expect(context.aggregates(:likes)).to eq('count' => 0, 'avg' => nil, 'max' => nil, 'min' => nil, 'sum' => 0)
    end
  end

  describe '#sum' do
    it 'returns zero' do
      expect(context.sum).to eq(0)
    end

    it 'returns zero when arg given' do
      expect(context.sum(:likes)).to eq(0)
    end
  end

  describe '#avg' do
    it 'returns nil' do
      expect(context.avg(:likes)).to be_nil
    end
  end

  describe '#min and #max' do
    it 'returns nil' do
      expect(context.min).to be_nil
      expect(context.max).to be_nil
    end

    it 'returns nil when arg given' do
      expect(context.min(:likes)).to be_nil
      expect(context.max(:likes)).to be_nil
    end
  end
end
