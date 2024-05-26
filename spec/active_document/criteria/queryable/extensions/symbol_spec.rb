# frozen_string_literal: true

require 'spec_helper'

describe Symbol do

  describe '.evolve' do

    context 'when provided nil' do

      it 'returns nil' do
        expect(described_class.evolve(nil)).to be_nil
      end
    end

    context 'when provided a string' do

      it 'returns the string as a symbol' do
        expect(described_class.evolve('test')).to eq(:test)
      end
    end
  end
end
