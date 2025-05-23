# frozen_string_literal: true

require 'spec_helper'

describe String do

  describe '#__evolve_date__' do

    context 'when the string is verbose' do

      let(:date) do
        '1st Jan 2010'
      end

      let(:evolved) do
        date.__evolve_date__
      end

      it 'returns the strings as a times' do
        expect(evolved).to eq(Time.new(2010, 1, 1, 0, 0, 0, 0).utc)
      end
    end

    context 'when the string is in international format' do

      let(:date) do
        '2010-1-1'
      end

      let(:evolved) do
        date.__evolve_date__
      end

      it 'returns the strings as a times' do
        expect(evolved).to eq(Time.new(2010, 1, 1, 0, 0, 0, 0).utc)
      end
    end
  end

  describe '#__evolve_time__' do

    context 'when the string is verbose' do

      let(:date) do
        '1st Jan 2010 12:00:00+01:00'
      end

      let(:evolved) do
        date.__evolve_time__
      end

      it 'returns the string as a utc time' do
        expect(evolved).to eq(Time.new(2010, 1, 1, 11, 0, 0, 0).utc)
      end
    end

    context 'when the string is in international format' do

      let(:date) do
        '2010-01-01 12:00:00+01:00'
      end

      let(:evolved) do
        date.__evolve_time__
      end

      it 'returns the string as a utc time' do
        expect(evolved).to eq(Time.new(2010, 1, 1, 11, 0, 0, 0).utc)
      end
    end

    context 'when setting ActiveSupport time zone' do
      time_zone_override 'Asia/Tokyo'

      let(:date) do
        '2010-01-01 5:00:00'
      end

      let(:evolved) do
        date.__evolve_time__
      end

      it "parses string using active support's time zone" do
        expect(evolved).to eq(Time.zone.parse(date).utc)
      end
    end
  end

  describe '#__sort_option__' do

    context 'when the string contains ascending' do

      let(:option) do
        'field_one ascending, field_two ascending'.__sort_option__
      end

      it 'returns the ascending sort option hash' do
        expect(option).to eq({ field_one: 1, field_two: 1 })
      end
    end

    context 'when the string contains asc' do

      let(:option) do
        'field_one asc, field_two asc'.__sort_option__
      end

      it 'returns the ascending sort option hash' do
        expect(option).to eq({ field_one: 1, field_two: 1 })
      end
    end

    context 'when the string contains ASCENDING' do

      let(:option) do
        'field_one ASCENDING, field_two ASCENDING'.__sort_option__
      end

      it 'returns the ascending sort option hash' do
        expect(option).to eq({ field_one: 1, field_two: 1 })
      end
    end

    context 'when the string contains ASC' do

      let(:option) do
        'field_one ASC, field_two ASC'.__sort_option__
      end

      it 'returns the ascending sort option hash' do
        expect(option).to eq({ field_one: 1, field_two: 1 })
      end
    end

    context 'when the string contains descending' do

      let(:option) do
        'field_one descending, field_two descending'.__sort_option__
      end

      it 'returns the descending sort option hash' do
        expect(option).to eq({ field_one: -1, field_two: -1 })
      end
    end

    context 'when the string contains desc' do

      let(:option) do
        'field_one desc, field_two desc'.__sort_option__
      end

      it 'returns the descending sort option hash' do
        expect(option).to eq({ field_one: -1, field_two: -1 })
      end
    end

    context 'when the string contains DESCENDING' do

      let(:option) do
        'field_one DESCENDING, field_two DESCENDING'.__sort_option__
      end

      it 'returns the descending sort option hash' do
        expect(option).to eq({ field_one: -1, field_two: -1 })
      end
    end

    context 'when the string contains DESC' do

      let(:option) do
        'field_one DESC, field_two DESC'.__sort_option__
      end

      it 'returns the descending sort option hash' do
        expect(option).to eq({ field_one: -1, field_two: -1 })
      end
    end
  end

  describe '.evolve' do
    subject(:evolved) { described_class.evolve(object) }

    context 'when provided a Regexp' do
      let(:object) { /\A[123]/ }

      it 'returns the regexp' do
        expect(evolved).to eq(/\A[123]/)
      end
    end

    context 'when provided a BSON::Regexp::Raw' do
      let(:object) { BSON::Regexp::Raw.new('^[123]') }

      it 'returns the BSON::Regexp::Raw' do
        expect(evolved).to eq(BSON::Regexp::Raw.new('^[123]'))
      end
    end

    context 'when provided an object' do
      let(:object) { 1234 }

      it 'returns the object as a string' do
        expect(evolved).to eq('1234')
      end
    end
  end
end
