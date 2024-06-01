# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Extensions::Date do

  describe '.demongoize' do
    subject(:converted) { Date.demongoize(object) }

    let(:expected) { Date.new(2010, 1, 1) }

    context 'when Date' do
      let(:object) { Date.new(2010, 1, 1) }

      it 'keeps the date' do
        is_expected.to eq(object)
        is_expected.to be_a(Date)
      end
    end

    context 'when Time' do
      let(:object) { Time.utc(2010, 1, 1, 0, 0, 0, 0) }

      it 'converts to a date' do
        is_expected.to eq(expected)
        is_expected.to be_a(Date)
      end
    end

    context 'when nil' do
      let(:object) { nil }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when valid String' do
      let(:object) { '2022-07-11 14:03:42 -0400' }
      let(:expected) { object.to_date }

      it 'returns a date' do
        is_expected.to eq expected
        is_expected.to be_a(Date)
      end
    end

    context 'when bogus String' do
      let(:object) { 'bogus' }
      let(:expected) { ActiveDocument::RawValue('bogus') }

      it 'returns RawValue' do
        is_expected.to eq expected
        is_expected.to be_a ActiveDocument::RawValue
      end
    end
  end

  describe '#mongoize' do

    let(:date) do
      Date.new(2010, 1, 1)
    end

    let(:time) do
      Time.utc(2010, 1, 1, 0, 0, 0, 0)
    end

    it 'returns the date as a time at midnight' do
      expect(date.mongoize).to eq(time)
    end
  end

  describe '.mongoize' do
    let(:date) do
      Date.new(2010, 1, 1)
    end

    let(:time) do
      Time.utc(2010, 1, 1, 0, 0, 0, 0)
    end

    let(:datetime) do
      time.to_datetime
    end

    context 'when the value is a date' do

      it 'converts to a date' do
        expect(Date.mongoize(date)).to eq(date)
        expect(Date.mongoize(date)).to be_a(Time)
      end
    end

    context 'when the value is a time' do

      it 'keeps the time' do
        expect(Date.mongoize(time)).to eq(date)
        expect(Date.mongoize(time)).to be_a(Time)
      end
    end

    context 'when the value is a datetime' do

      it 'converts to a time' do
        expect(Date.mongoize(datetime)).to eq(date)
        expect(Date.mongoize(datetime)).to be_a(Time)
      end
    end

    context 'when the value is uncastable' do
      it 'returns nil' do
        # TODO: type casting error
        expect { Date.mongoize('bogus') }.to raise_error(ArgumentError)
        # expect(Date.mongoize('bogus')).to be_nil
      end
    end
  end
end
