# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::TypeConverters::Time do

  shared_examples_for 'converts to ActiveSupport::TimeWithZone' do
    it 'is an ActiveSupport::TimeWithZone' do
      expect(converted.class).to eq(ActiveSupport::TimeWithZone)
    end

    it 'is equal to expected time' do
      expect(expected_time).to be_a(ActiveSupport::TimeWithZone)
      expect(converted).to eq(expected_time)
    end
  end

  shared_examples_for 'converts to Time' do
    it 'is a Time' do
      expect(converted.class).to eq(Time)
    end

    it 'is equal to expected time' do
      expect(expected_time).to be_a(Time)
      expect(converted).to eq(expected_time)
    end
  end

  shared_examples_for 'maintains precision when cast' do
    it 'maintains precision' do
      # 123457 happens to be consistently obtained by various tests
      expect(converted.to_f.to_s).to match(/\.123457/)
    end
  end

  describe '.to_database_cast' do
    # TODO: RawValue
    time_zone_override 'Asia/Tokyo'
    subject(:converted) { described_class.to_database_cast(object) }

    context 'when Time' do
      let(:object) { Time.at(1543331265.123457) } # rubocop:disable Rails/TimeZone
      let(:expected_time) { object.utc }

      it_behaves_like 'converts to Time'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when DateTime' do
      let(:object) do
        # DateTime has time zone information, even if a time zone is not provided
        # when parsing a string
        DateTime.parse('2012-06-17 18:42:15.123457')
      end
      let(:expected_time) { object.to_time.utc }

      it_behaves_like 'converts to Time'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when ActiveSupport::TimeWithZone' do
      let(:object) do
        ActiveSupport::TimeZone['Magadan'].at(1543331265.123457)
      end
      let(:expected_time) { object.utc }

      it do
        expect(object).to be_a(ActiveSupport::TimeWithZone)
      end

      it_behaves_like 'converts to Time'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when Date' do
      let(:object) { Date.new(2010, 1, 1) }
      let(:expected_time) { Time.zone.local(2010, 1, 1, 0, 0, 0, 0) }

      it_behaves_like 'converts to Time'
    end

    context 'when Array' do
      let(:object) { [2010, 11, 19, 0, 24, 49.123457] }

      # In AS time zone (could be different from Ruby time zone)
      let(:expected_time) { Time.zone.local(*object).utc }

      it_behaves_like 'converts to Time'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when Integer' do
      let(:object) { 1335532685 }
      let(:expected_time) { Time.at(object).utc }

      it_behaves_like 'converts to Time'
    end

    context 'when Float' do
      let(:object) { 1335532685.123457 }
      let(:expected_time) { Time.at(object).utc }

      it_behaves_like 'converts to Time'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when BigDecimal' do
      let(:object) { BigDecimal('1335532685.123457') }
      let(:expected_time) { Time.at(object).utc }

      it_behaves_like 'converts to Time'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when String' do
      context 'when the string is a valid time with time zone' do
        let(:object) { '2010-11-19 00:24:49.123457 +1100' }
        let(:expected_time) { Time.parse('2010-11-18 13:24:49.123457 +0000').utc }

        it_behaves_like 'converts to Time'
        it_behaves_like 'maintains precision when cast'
      end

      context 'when the string is a valid time without time zone' do
        let(:object) { '2010-11-19 00:24:49.123457' }
        let(:expected_time) { Time.parse('2010-11-18 15:24:49.123457 +0000').utc }

        it_behaves_like 'converts to Time'
        it_behaves_like 'maintains precision when cast'
      end

      context 'when the string is a valid time without time' do
        let(:object) { '2010-11-19' }
        let(:expected_time) { Time.parse('2010-11-18 15:00:00 +0000').utc }

        it_behaves_like 'converts to Time'
      end

      context 'when the string is an invalid time' do
        let(:object) { 'bad string' }

        it 'raises an error' do
          expect { converted }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '.to_ruby_cast' do
    time_zone_override 'Asia/Tokyo'
    subject(:converted) { described_class.to_ruby_cast(object) }

    context 'when Time' do
      let(:object) { Time.at(1543331265.123457) } # rubocop:disable Rails/TimeZone
      let(:expected_time) { object.in_time_zone }

      it_behaves_like 'converts to ActiveSupport::TimeWithZone'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when DateTime' do
      let(:object) do
        # DateTime has time zone information, even if a time zone is not provided
        # when parsing a string
        DateTime.parse('2012-06-17 18:42:15.123457')
      end
      let(:expected_time) { object.to_time.in_time_zone }

      it_behaves_like 'converts to ActiveSupport::TimeWithZone'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when ActiveSupport::TimeWithZone' do
      let(:object) do
        ActiveSupport::TimeZone['Magadan'].at(1543331265.123457)
      end
      let(:expected_time) { object.in_time_zone }

      it do
        expect(object).to be_a(ActiveSupport::TimeWithZone)
      end

      it_behaves_like 'converts to ActiveSupport::TimeWithZone'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when Date' do
      let(:object) { Date.new(2010, 1, 1) }
      let(:expected_time) { Time.zone.local(2010, 1, 1, 0, 0, 0, 0) }

      it_behaves_like 'converts to ActiveSupport::TimeWithZone'
    end

    context 'when Array' do
      let(:object) { [2010, 11, 19, 0, 24, 49.123457] }

      # In AS time zone (could be different from Ruby time zone)
      let(:expected_time) { Time.zone.local(*object).in_time_zone }

      it 'converts to the as time zone' do
        expect(converted.zone).to eq('JST')
      end

      it_behaves_like 'converts to ActiveSupport::TimeWithZone'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when Integer' do
      let(:object) { 1335532685 }
      let(:expected_time) { Time.at(object).in_time_zone }

      it_behaves_like 'converts to ActiveSupport::TimeWithZone'
    end

    context 'when Float' do
      let(:object) { 1335532685.123457 }
      let(:expected_time) { Time.at(object).in_time_zone }

      it_behaves_like 'converts to ActiveSupport::TimeWithZone'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when BigDecimal' do
      let(:object) { BigDecimal('1335532685.123457') }
      let(:expected_time) { Time.at(object).in_time_zone }

      it_behaves_like 'converts to ActiveSupport::TimeWithZone'
      it_behaves_like 'maintains precision when cast'
    end

    context 'when String' do
      context 'when the string is a valid time with time zone' do
        let(:object) { '2010-11-19 00:24:49.123457 +1100' }
        let(:expected_time) { Time.parse('2010-11-18 13:24:49.123457 +0000').in_time_zone }

        it 'converts to the AS time zone' do
          expect(converted.zone).to eq('JST')
        end

        it_behaves_like 'converts to ActiveSupport::TimeWithZone'
        it_behaves_like 'maintains precision when cast'
      end

      context 'when the string is a valid time without time zone' do
        let(:object) { '2010-11-19 00:24:49.123457' }
        let(:expected_time) { Time.parse('2010-11-18 15:24:49.123457 +0000').in_time_zone }

        it 'converts to the AS time zone' do
          expect(converted.zone).to eq('JST')
        end

        it_behaves_like 'converts to ActiveSupport::TimeWithZone'
        it_behaves_like 'maintains precision when cast'
      end

      context 'when the string is a valid time without time' do
        let(:object) { '2010-11-19' }
        let(:expected_time) { Time.parse('2010-11-18 15:00:00 +0000').in_time_zone }

        it 'converts to the AS time zone' do
          expect(converted.zone).to eq('JST')
        end

        it_behaves_like 'converts to ActiveSupport::TimeWithZone'
      end

      context 'when the string is an invalid time' do
        let(:object) { 'bad string' }

        it 'raises an error' do
          expect(converted).to eq ActiveDocument::RawValue(object)
        end
      end
    end
  end
end
