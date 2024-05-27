# frozen_string_literal: true

require 'spec_helper'

describe 'Criteria logical operations' do
  let!(:ap) { Band.create!(name: 'Astral Projection', origin: 'SFX', genres: %w[Goa Psy]) }
  let!(:im) { Band.create!(name: 'Infected Mushroom', origin: 'Computers', genres: ['Psy']) }
  let!(:sp) { Band.create!(name: 'Sun Project', genres: ['Goa']) }

  describe '.all_of' do
    it 'combines conditions on different fields given as hashes' do
      bands = Band.where(name: /Proj/).all_of(genres: 'Psy')
      expect(bands.to_a).to eq([ap])
    end

    it 'combines conditions on different fields given as scopes' do
      bands = Band.where(name: /Proj/).all_of(Band.where(genres: 'Psy'))
      expect(bands.to_a).to eq([ap])
    end

    it 'combines conditions on same field given as hashes' do
      bands = Band.where(name: /Proj/).all_of(name: /u/)
      expect(bands.to_a).to eq([sp])
    end

    it 'combines conditions on same field given as scopes' do
      bands = Band.where(name: /Proj/).all_of(Band.where(name: /u/))
      expect(bands.to_a).to eq([sp])
    end

    it 'combines existing `$and` clause in query and `where` condition' do
      bands = Band.where(id: 1).all_of({ year: { '$in' => [2020] } }, { year: { '$in' => [2021] } }).where(id: 2)
      expect(bands.selector).to eq({
        '_id' => 1,
        'year' => { '$in' => [2020] },
        '$and' => [{ 'year' => { '$in' => [2021] } }, { '_id' => 2 }]
      })
    end
  end

  describe '.any_of' do
    it 'combines conditions on different fields given as hashes' do
      bands = Band.any_of({ name: /Sun/ }, { origin: 'SFX' })
      expect(bands.order_by(name: 1).to_a).to eq([ap, sp])
    end

    it 'combines conditions on different fields given as scopes' do
      bands = Band.any_of({ name: /Sun/ }, Band.where(origin: 'SFX'))
      expect(bands.order_by(name: 1).to_a).to eq([ap, sp])
    end

    it 'combines conditions on same field given as hashes' do
      bands = Band.any_of({ name: /jecti/ }, { name: /ush/ })
      expect(bands.order_by(name: 1).to_a).to eq([ap, im])
    end

    it 'combines conditions on same field given as scopes' do
      bands = Band.any_of({ name: /jecti/ }, Band.where(name: /ush/))
      expect(bands.order_by(name: 1).to_a).to eq([ap, im])
    end

    context 'when using a symbol operator' do
      context 'when field has a serializer' do
        let!(:doc) { Dokument.create! }

        it 'sets the $or selector' do
          scope = Dokument.any_of({ created_at: { '$lte' => DateTime.now } }, { foo: 'bar' }).sort(id: 1)
          # input was converted from DateTime to Time
          expect(scope.criteria.selector['$or'].first['created_at']['$lte']).to be_a(Time)
          expect(scope.criteria.selector['$or'].last['foo']).to eq('bar')
          expect(scope.to_a).to eq([doc])
        end
      end
    end
  end

  describe '.none_of' do
    it 'combines conditions on different fields given as hashes' do
      bands = Band.none_of({ name: /Sun/ }, { origin: 'SFX' })
      expect(bands.order_by(name: 1).to_a).to eq([im])
    end

    it 'combines conditions on different fields given as scopes' do
      bands = Band.none_of({ name: /Sun/ }, Band.where(origin: 'SFX'))
      expect(bands.order_by(name: 1).to_a).to eq([im])
    end

    it 'combines conditions on same field given as hashes' do
      bands = Band.none_of({ name: /jecti/ }, { name: /ush/ })
      expect(bands.order_by(name: 1).to_a).to eq([sp])
    end

    it 'combines conditions on same field given as scopes' do
      bands = Band.none_of({ name: /jecti/ }, Band.where(name: /ush/))
      expect(bands.order_by(name: 1).to_a).to eq([sp])
    end

    context 'when using a symbol operator' do
      context 'when field has a serializer' do
        let!(:doc) { Dokument.create! }

        it 'sets the $or selector' do
          scope = Dokument.none_of({ created_at: { '$gt' => DateTime.now } }, { foo: 'bar' }).sort(id: 1)
          # input was converted from DateTime to Time
          expect(scope.criteria.selector['$nor'].first['created_at']['$gt']).to be_a(Time)
          expect(scope.criteria.selector['$nor'].last['foo']).to eq('bar')
          expect(scope.to_a).to eq([doc])
        end
      end
    end
  end

  describe '.not' do
    context 'hash argument with string value' do
      let(:actual) do
        Band.not(name: 'test').selector
      end

      let(:expected) do
        { 'name' => { '$ne' => 'test' } }
      end

      it 'expands to use $ne' do
        expect(actual).to eq(expected)
      end
    end

    context 'hash argument with regexp value' do
      let(:actual) do
        Band.not(name: /test/).selector
      end

      let(:expected) do
        { 'name' => { '$not' => /test/ } }
      end

      it 'expands to use $not' do
        expect(actual).to eq(expected)
      end
    end
  end
end
