# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::PluckEnumerator do
  describe '.prepare_pluck' do
    context 'with simple field names' do
      let(:result) { described_class.prepare_pluck(Band, %i[name likes]) }

      it 'returns normalized field names' do
        expect(result[:field_names]).to eq(%w[name likes])
      end

      it 'returns empty projection when not requested' do
        expect(result[:projection]).to eq({})
      end
    end

    context 'with aliased field names' do
      let(:result) { described_class.prepare_pluck(Product, [:price]) }

      it 'keeps the requested field name for extraction' do
        # prepare_pluck uses database_field_name which returns the canonical name
        # The actual alias resolution happens during extract_value
        expect(result[:field_names]).to eq(%w[price])
      end
    end

    context 'with prepare_projection: true' do
      let(:result) { described_class.prepare_pluck(Band, %i[name likes], prepare_projection: true) }

      it 'returns projection hash' do
        expect(result[:projection]).to eq({ 'name' => true, 'likes' => true })
      end
    end

    context 'with localized field names' do
      with_default_i18n_configs

      let(:result) { described_class.prepare_pluck(Product, [:name], prepare_projection: true) }

      it 'normalizes localized field names for projection' do
        expect(result[:field_names]).to eq(%w[name])
        expect(result[:projection]).to eq({ 'name' => true })
      end
    end

    context 'with locale-specific field names' do
      with_default_i18n_configs

      let(:result) { described_class.prepare_pluck(Product, [:'name.de'], prepare_projection: true) }

      it 'preserves locale-specific field names' do
        expect(result[:field_names]).to eq(%w[name.de])
        # The projection includes the full path for locale-specific queries
        expect(result[:projection]).to eq({ 'name.de' => true })
      end
    end
  end

  describe '.pluck_from_documents' do
    context 'with a single field' do
      let(:docs) do
        [
          BSON::Document.new('name' => 'Depeche Mode', 'likes' => 100),
          BSON::Document.new('name' => 'New Order', 'likes' => 200)
        ]
      end

      let(:result) { described_class.pluck_from_documents(Band, docs, %w[name]) }

      it 'returns array of single values' do
        expect(result).to eq(['Depeche Mode', 'New Order'])
      end
    end

    context 'with multiple fields' do
      let(:docs) do
        [
          BSON::Document.new('name' => 'Depeche Mode', 'likes' => 100),
          BSON::Document.new('name' => 'New Order', 'likes' => 200)
        ]
      end

      let(:result) { described_class.pluck_from_documents(Band, docs, %w[name likes]) }

      it 'returns array of arrays' do
        expect(result).to eq([['Depeche Mode', 100], ['New Order', 200]])
      end
    end

    context 'with aliased fields' do
      let(:docs) do
        [
          BSON::Document.new('p' => 100),
          BSON::Document.new('p' => 200)
        ]
      end

      let(:result) { described_class.pluck_from_documents(Product, docs, %w[p]) }

      it 'extracts values using database field names' do
        expect(result).to eq([100, 200])
      end
    end

    context 'with nil values' do
      let(:docs) do
        [
          BSON::Document.new('name' => 'Depeche Mode'),
          BSON::Document.new('name' => nil)
        ]
      end

      let(:result) { described_class.pluck_from_documents(Band, docs, %w[name]) }

      it 'preserves nil values' do
        expect(result).to eq(['Depeche Mode', nil])
      end
    end

    context 'with missing fields' do
      let(:docs) do
        [
          BSON::Document.new('name' => 'Depeche Mode'),
          BSON::Document.new({})
        ]
      end

      let(:result) { described_class.pluck_from_documents(Band, docs, %w[name]) }

      it 'returns nil for missing fields' do
        expect(result).to eq(['Depeche Mode', nil])
      end
    end
  end

  describe '.extract_value' do
    context 'with a simple field' do
      let(:attrs) { BSON::Document.new('name' => 'Depeche Mode') }

      it 'extracts the value' do
        expect(described_class.extract_value(Band, attrs, 'name')).to eq('Depeche Mode')
      end
    end

    context 'with an aliased field' do
      let(:attrs) { BSON::Document.new('p' => 500) }

      it 'extracts the value using database field name' do
        expect(described_class.extract_value(Product, attrs, 'p')).to eq(500)
      end
    end

    context 'with a nested embedded field' do
      let(:attrs) do
        BSON::Document.new('label' => { 'name' => 'Sony' })
      end

      it 'extracts nested values' do
        expect(described_class.extract_value(Band, attrs, 'label.name')).to eq('Sony')
      end
    end

    context 'with an embeds_many field' do
      let(:attrs) do
        BSON::Document.new('labels' => [{ 'name' => 'Sony' }, { 'name' => 'EMI' }])
      end

      it 'extracts values from all embedded documents' do
        expect(described_class.extract_value(Band, attrs, 'labels.name')).to eq(%w[Sony EMI])
      end
    end

    context 'with a localized field' do
      with_default_i18n_configs

      let(:attrs) do
        BSON::Document.new('name' => { 'en' => 'english-text', 'de' => 'deutsch-text' })
      end

      it 'returns the value for current locale' do
        I18n.with_locale(:de) do
          expect(described_class.extract_value(Product, attrs, 'name')).to eq('deutsch-text')
        end
      end
    end

    context 'with a _translations field' do
      with_default_i18n_configs

      let(:attrs) do
        BSON::Document.new('name' => { 'en' => 'english-text', 'de' => 'deutsch-text' })
      end

      it 'returns the full translations hash' do
        expect(described_class.extract_value(Product, attrs, 'name_translations')).to eq(
          { 'en' => 'english-text', 'de' => 'deutsch-text' }
        )
      end
    end

    context 'with a specific locale from _translations' do
      with_default_i18n_configs

      let(:attrs) do
        BSON::Document.new('name' => { 'en' => 'english-text', 'de' => 'deutsch-text' })
      end

      it 'returns the value for the specific locale' do
        expect(described_class.extract_value(Product, attrs, 'name_translations.de')).to eq('deutsch-text')
      end
    end

    context 'with a demongoizable field' do
      let(:attrs) { BSON::Document.new('sales' => '1E2') }

      it 'demongoizes the value' do
        expect(described_class.extract_value(Label, attrs, 'sales')).to eq(BigDecimal('1E2'))
      end
    end
  end

  describe '#each' do
    before do
      Band.create!(name: 'Depeche Mode', likes: 100)
      Band.create!(name: 'New Order', likes: 200)
    end

    let(:view) { Band.collection.find }
    let(:enumerator) { described_class.new(Band, view, [:name]) }

    it 'yields each plucked value' do
      results = enumerator.map { |name| name }
      expect(results).to contain_exactly('Depeche Mode', 'New Order')
    end

    it 'returns an enumerator when no block given' do
      expect(enumerator.each).to be_a(Enumerator)
    end

    it 'returns self when block given' do
      result = enumerator.each { |_| }
      expect(result).to eq(enumerator)
    end

    context 'with multiple fields' do
      let(:enumerator) { described_class.new(Band, view, %i[name likes]) }

      it 'yields arrays of values' do
        results = enumerator.map { |values| values }
        expect(results).to contain_exactly(['Depeche Mode', 100], ['New Order', 200])
      end
    end
  end

  describe 'Enumerable inclusion' do
    before do
      Band.create!(name: 'Depeche Mode', likes: 100)
      Band.create!(name: 'New Order', likes: 200)
    end

    let(:view) { Band.collection.find }
    let(:enumerator) { described_class.new(Band, view, [:name]) }

    it 'supports #to_a' do
      expect(enumerator.to_a).to contain_exactly('Depeche Mode', 'New Order')
    end

    it 'supports #map' do
      expect(enumerator.map(&:upcase)).to contain_exactly('DEPECHE MODE', 'NEW ORDER')
    end

    it 'supports #select' do
      expect(enumerator.select { |name| name.start_with?('D') }).to eq(['Depeche Mode'])
    end

    it 'supports #first' do
      expect(enumerator.first).to be_in(['Depeche Mode', 'New Order'])
    end
  end
end
