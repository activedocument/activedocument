# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Extensions::Decimal128 do

  let(:decimal128) do
    BSON::Decimal128.new('0.0005')
  end

  describe '#__evolve_decimal128__' do

    it 'returns the same instance' do
      expect(decimal128.__evolve_decimal128__).to be(decimal128)
    end
  end

  describe '.evolve' do

    context 'when provided a single decimal128' do

      let(:evolved) do
        BSON::Decimal128.evolve(decimal128)
      end

      it 'returns the decimal128' do
        expect(evolved).to be(decimal128)
      end
    end
  end
end
