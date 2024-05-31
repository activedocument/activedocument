# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Extensions::DateTime do

  describe '.demongoize' do

    let!(:time) do
      Time.now.utc
    end

    let(:date_time) do
      DateTime.demongoize(time)
    end

    it 'converts to a datetime' do
      expect(date_time).to be_a(DateTime)
    end

    it 'does not change the time' do
      expect(DateTime.demongoize(time)).to eq(time)
    end

    context 'when using utc' do
      config_override :use_utc, true

      context 'when setting a utc time' do

        let(:user) do
          User.new
        end

        let(:date) do
          DateTime.parse('2012-01-23 08:26:14 PM')
        end

        before do
          user.last_login = date
        end

        it 'does not return the time with time zone applied' do
          expect(user.last_login).to eq(date)
        end
      end
    end

    context 'when demongoizing a string' do

      let(:date) { '2022-07-11 14:03:42 -0400' }

      it 'returns a date' do
        expect(DateTime.demongoize(date)).to eq(date.to_datetime)
      end
    end
  end

  describe '.mongoize' do

    context 'when the string is an invalid time' do

      let(:mongoized) do
        DateTime.mongoize('time')
      end

      it 'returns nil' do
        expect(mongoized).to be_nil
      end
    end
  end

  describe '#mongoize' do

    let!(:date_time) do
      Time.now.utc.to_datetime
    end

    context 'when the string is an invalid time' do

      it 'returns the date time as a time' do
        expect(date_time.mongoize).to be_a(Time)
      end
    end
  end
end
