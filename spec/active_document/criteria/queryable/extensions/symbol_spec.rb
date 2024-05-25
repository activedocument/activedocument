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

  describe '#__expr_part__' do

    let(:specified) do
      :field.__expr_part__(10)
    end

    it 'returns the string with the value' do
      expect(specified).to eq({ field: 10 })
    end

    context 'with a regexp' do

      let(:specified) do
        :field.__expr_part__(/test/)
      end

      it 'returns the symbol with the value' do
        expect(specified).to eq({ field: /test/ })
      end

    end

    context 'when negated' do

      context 'with a regexp' do

        let(:specified) do
          :field.__expr_part__(/test/, true)
        end

        it 'returns the symbol with the value negated' do
          expect(specified).to eq({ field: { '$not' => /test/ } })
        end

      end

      context 'with anything else' do

        let(:specified) do
          :field.__expr_part__('test', true)
        end

        it 'returns the symbol with the value negated' do
          expect(specified).to eq({ field: { '$ne' => 'test' } })
        end

      end
    end
  end
end
