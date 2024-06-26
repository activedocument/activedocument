# frozen_string_literal: true

require 'spec_helper'

describe Array do

  describe '.evolve' do

    context 'when provided an Array' do

      let(:array) do
        [1, 2, 3]
      end

      it 'returns an array' do
        expect(described_class.evolve(array)).to eq([1, 2, 3])
      end

      it "doesn't mutate its argument" do
        expect { described_class.evolve(array.freeze) }.to_not raise_error
      end
    end

    context 'when provided nil' do

      it 'returns nil' do
        expect(described_class.evolve(nil)).to be_nil
      end
    end

    context 'when provided another object' do

      it 'returns the object' do
        expect(described_class.evolve('testing')).to eq('testing')
      end
    end

    context 'when providing a set' do

      it 'returns an array' do
        expect(described_class.evolve([1, 2, 3].to_set)).to eq([1, 2, 3])
      end
    end
  end

  describe '#__deep_copy__' do

    let(:inner) do
      [3, 4]
    end

    let(:array) do
      [1, 2, inner]
    end

    let(:copy) do
      array.__deep_copy__
    end

    it 'returns an equal array' do
      expect(copy).to eq(array)
    end

    it 'returns a copy' do
      expect(copy).to_not equal(array)
    end

    it 'deep copies the elements' do
      expect(copy[2]).to_not equal(inner)
    end
  end

  describe '#__evolve_date__' do

    context 'when the array is composed of dates' do

      let(:date) do
        Date.new(2010, 1, 1)
      end

      let(:evolved) do
        [date].__evolve_date__
      end

      let(:expected) do
        Time.utc(2010, 1, 1, 0, 0, 0, 0)
      end

      it 'returns the array with evolved times' do
        expect(evolved).to eq([expected])
      end
    end

    context 'when the array is composed of strings' do

      let(:date) do
        Date.parse('1st Jan 2010')
      end

      let(:evolved) do
        [date.to_s].__evolve_date__
      end

      it 'returns the strings as a times' do
        expect(evolved).to eq([Time.new(2010, 1, 1, 0, 0, 0, 0).utc])
      end
    end

    context 'when the array is composed of integers' do

      let(:time) do
        Time.utc(2010, 1, 1, 0, 0, 0, 0)
      end

      let(:integer) do
        time.to_i
      end

      let(:evolved) do
        [integer].__evolve_date__
      end

      let(:expected) do
        Time.at(integer)
      end

      it 'returns the integers as times' do
        expect(evolved).to eq([time])
      end
    end

    context 'when the array is composed of floats' do

      let(:time) do
        Time.utc(2010, 1, 1, 0, 0, 0, 0)
      end

      let(:float) do
        time.to_f
      end

      let(:evolved) do
        [float].__evolve_date__
      end

      let(:expected) do
        Time.at(float)
      end

      it 'returns the floats as times' do
        expect(evolved).to eq([time])
      end
    end
  end

  describe '#__evolve_time__' do

    context 'when the array is composed of times' do

      let(:date) do
        Time.new(2010, 1, 1, 12, 0, 0)
      end

      let(:evolved) do
        [date].__evolve_time__
      end

      let(:expected) do
        Time.new(2010, 1, 1, 12, 0, 0).utc
      end

      it 'returns the array with evolved times' do
        expect(evolved).to eq([expected])
      end

      it 'returns utc times' do
        expect(evolved.first.utc_offset).to eq(0)
      end
    end

    context 'when the array is composed of strings' do

      let(:date) do
        Time.parse('1st Jan 2010 12:00:00+01:00')
      end

      let(:evolved) do
        [date.to_s].__evolve_time__
      end

      it 'returns the strings as a times' do
        expect(evolved).to eq([date.to_time])
      end

      it 'returns the times in utc' do
        expect(evolved.first.utc_offset).to eq(0)
      end
    end

    context 'when the array is composed of integers' do

      let(:integer) do
        1331890719
      end

      let(:evolved) do
        [integer].__evolve_time__
      end

      let(:expected) do
        Time.at(integer).utc
      end

      it 'returns the integers as times' do
        expect(evolved).to eq([expected])
      end

      it 'returns the times in utc' do
        expect(evolved.first.utc_offset).to eq(0)
      end
    end

    context 'when the array is composed of floats' do

      let(:float) do
        1331890719.413
      end

      let(:evolved) do
        [float].__evolve_time__
      end

      let(:expected) do
        Time.at(float).utc
      end

      it 'returns the floats as times' do
        expect(evolved).to eq([expected])
      end

      it 'returns the times in utc' do
        expect(evolved.first.utc_offset).to eq(0)
      end
    end
  end

  describe '#__sort_option__' do

    context 'when the array is one dimensional' do

      it 'returns a hash of sort options' do
        expect([:field, 1].__sort_option__).to eq({ field: 1 })
      end
    end

    context 'when the array is multi dimensional' do

      it 'returns a hash of sort options' do
        expect([[:field, 1]].__sort_option__).to eq({ field: 1 })
      end
    end
  end

  describe '#__sort_pair__' do

    context 'when the direction is a symbol' do

      it 'converts the symbol to an integer' do
        expect(%i[field asc].__sort_pair__).to eq({ field: 1 })
      end
    end

    context 'when the direction is an integer' do

      it 'returns the array as a hash' do
        expect([:field, 1].__sort_pair__).to eq({ field: 1 })
      end
    end
  end

  describe '#__sort_option__' do

    context 'when the array is multi-dimensional' do

      context 'when the arrays have integer values' do

        let(:selection) do
          [[:field_one, 1], [:field_two, -1]]
        end

        it 'adds the sorting criteria' do
          expect(selection.__sort_option__).to eq(
            { field_one: 1, field_two: -1 }
          )
        end
      end

      context 'when the arrays have symbol values' do

        let(:selection) do
          [%i[field_one asc], %i[field_two desc]]
        end

        it 'adds the sorting criteria' do
          expect(selection.__sort_option__).to eq(
            { field_one: 1, field_two: -1 }
          )
        end
      end

      context 'when the arrays have string values' do

        let(:selection) do
          [[:field_one, 'asc'], [:field_two, 'desc']]
        end

        it 'adds the sorting criteria' do
          expect(selection.__sort_option__).to eq(
            { field_one: 1, field_two: -1 }
          )
        end
      end
    end

    context 'when the array is one-dimensional' do

      context 'when the arrays have integer values' do

        let(:selection) do
          [:field_one, 1]
        end

        it 'adds the sorting criteria' do
          expect(selection.__sort_option__).to eq(
            { field_one: 1 }
          )
        end
      end
    end
  end
end
