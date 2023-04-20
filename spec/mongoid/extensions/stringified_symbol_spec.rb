# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::StringifiedSymbol do

  describe '.demongoize' do

    context 'when the object is not a symbol' do

      it 'returns the symbol' do
        expect(described_class.demongoize('test')).to eq(:test)
      end
    end

    context 'when the object is a symbol' do

      it 'returns the symbol' do
        expect(described_class.demongoize(:test)).to eq(:test)
      end
    end

    context 'when the object is a BSON Symbol' do

      it 'returns a symbol' do
        expect(described_class.demongoize(BSON::Symbol::Raw.new(:test))).to eq(:test)
      end
    end

    context 'when the object is an integer' do

      it 'returns a symbol' do
        expect(described_class.demongoize(14)).to eq(:'14')
      end
    end

    context 'when the object is nil' do

      it 'returns nil' do
        expect(described_class.demongoize(nil)).to be_nil
      end
    end
  end

  describe '.mongoize' do

    context 'when the object is not a symbol' do

      it 'returns the object' do
        expect(described_class.mongoize('test')).to eq('test')
      end

      it 'returns the string' do
        expect(described_class.mongoize([0, 1, 2])).to eq('[0, 1, 2]')
      end

      it 'returns the string' do
        expect(described_class.mongoize(2)).to eq('2')
      end
    end

    context 'when the object is a symbol' do

      it 'returns a string' do
        expect(described_class.mongoize(:test)).to eq('test')
      end
    end

    context 'when the object is nil' do

      it 'returns nil' do
        expect(described_class.mongoize(nil)).to be_nil
      end
    end
  end

  describe '#mongoize' do

    it 'returns self' do
      expect(:test.mongoize).to eq(:test)
    end
  end
end
