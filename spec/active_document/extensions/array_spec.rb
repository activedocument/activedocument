# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Extensions::Array do

  describe '#delete_one' do

    context "when the object doesn't exist" do

      let(:array) do
        []
      end

      let!(:deleted) do
        array.delete_one('1')
      end

      it 'returns nil' do
        expect(deleted).to be_nil
      end
    end

    context 'when the object exists once' do

      let(:array) do
        %w[1 2]
      end

      let!(:deleted) do
        array.delete_one('1')
      end

      it 'deletes the object' do
        expect(array).to eq(['2'])
      end

      it 'returns the object' do
        expect(deleted).to eq('1')
      end
    end

    context 'when the object exists more than once' do

      let(:array) do
        %w[1 2 1]
      end

      let!(:deleted) do
        array.delete_one('1')
      end

      it 'deletes the first object' do
        expect(array).to eq(%w[2 1])
      end

      it 'returns the object' do
        expect(deleted).to eq('1')
      end
    end
  end

  describe '.demongoize' do

    let(:array) do
      [1, 2, 3]
    end

    it 'returns the array' do
      expect(Array.demongoize(array)).to eq(array)
    end
  end

  describe '.mongoize' do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:input) do
      [date]
    end

    let(:mongoized) do
      Array.mongoize(input)
    end

    it 'mongoizes each element in the array' do
      expect(mongoized.first).to be_a(Time)
    end

    it 'converts the elements properly' do
      expect(mongoized.first).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
    end

    context 'when passing in a set' do
      let(:input) do
        [date].to_set
      end

      it 'mongoizes to an array' do
        expect(mongoized).to be_a(Array)
      end

      it 'converts the elements properly' do
        expect(mongoized.first).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
      end
    end
  end

  describe '#mongoize' do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:array) do
      [date]
    end

    let(:mongoized) do
      array.mongoize
    end

    it 'mongoizes each element in the array' do
      expect(mongoized.first).to be_a(Time)
    end

    it 'converts the elements properly' do
      expect(mongoized.first).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
    end
  end

  describe '.resizable?' do

    it 'returns true' do
      expect(Array).to be_resizable
    end
  end

  describe '#resiable?' do

    it 'returns true' do
      expect([]).to be_resizable
    end
  end
end
