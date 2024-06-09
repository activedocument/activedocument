# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Extensions::Hash do

  describe '.demongoize' do

    let(:hash) do
      { field: 1 }
    end

    it 'returns the hash' do
      expect(Hash.demongoize(hash)).to eq(hash)
    end

    context 'when object is nil' do
      let(:demongoized) do
        Hash.demongoize(nil)
      end

      it 'returns nil' do
        expect(demongoized).to be_nil
      end
    end

    context 'when the object is uncastable' do
      let(:demongoized) do
        Hash.demongoize(1)
      end

      it 'returns the object' do
        expect(demongoized).to eq(1)
      end
    end
  end

  describe '.mongoize' do

    context "when object isn't nil" do

      let(:date) do
        Date.new(2012, 1, 1)
      end

      let(:hash) do
        { date: date }
      end

      let(:mongoized) do
        Hash.mongoize(hash)
      end

      it 'mongoizes each element in the hash' do
        expect(mongoized[:date]).to be_a(Time)
      end

      it 'converts the elements properly' do
        expect(mongoized[:date]).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
      end

      it 'mongoizes to a BSON::Document' do
        expect(mongoized).to be_a(BSON::Document)
      end
    end

    context 'when object is nil' do
      let(:mongoized) do
        Hash.mongoize(nil)
      end

      it 'returns nil' do
        expect(mongoized).to be_nil
      end
    end

    context 'when the object is uncastable' do
      let(:mongoized) do
        Hash.mongoize(1)
      end

      it 'returns nil' do
        expect(mongoized).to be_nil
      end
    end

    describe 'when mongoizing a BSON::Document' do
      let(:mongoized) do
        Hash.mongoize(BSON::Document.new({ x: 1, y: 2 }))
      end

      it 'returns the same hash' do
        expect(mongoized).to eq({ 'x' => 1, 'y' => 2 })
      end

      it 'returns a BSON::Document' do
        expect(mongoized).to be_a(BSON::Document)
      end
    end
  end

  describe '#mongoize' do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:hash) do
      { date: date }
    end

    let(:mongoized) do
      hash.mongoize
    end

    it 'mongoizes each element in the hash' do
      expect(mongoized[:date]).to be_a(Time)
    end

    it 'converts the elements properly' do
      expect(mongoized[:date]).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
    end
  end

  describe '#resizable?' do

    it 'returns true' do
      expect({}).to be_resizable
    end
  end

  describe '.resizable?' do

    it 'returns true' do
      expect(Hash).to be_resizable
    end
  end
end
