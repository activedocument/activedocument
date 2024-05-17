# frozen_string_literal: true

require 'spec_helper'

describe BSON::Binary do

  describe '#mongoize' do

    let(:binary) do
      described_class.new('testing', :md5)
    end

    it 'returns the binary' do
      expect(binary.mongoize).to eq(binary)
    end
  end

  %i[mongoize demongoize].each do |method|
    describe ".#{method}" do

      let(:binary) do
        described_class.new('testing')
      end

      let(:evaluated) do
        described_class.send(method, value)
      end

      context 'when mongoizing a BSON::Binary' do

        let(:value) { binary }

        it 'returns the binary' do
          expect(evaluated).to eq(binary)
        end
      end

      context 'when mongoizing a String' do

        let(:value) { 'testing' }

        it 'returns it as binary' do
          expect(evaluated).to eq(binary)
        end
      end

      context 'when mongoizing nil' do

        let(:value) { nil }

        it 'returns nil' do
          expect(evaluated).to be_nil
        end
      end

      context 'when mongoizing an invalid type' do

        let(:value) { true }

        it 'returns nil' do
          expect(evaluated).to be_nil
        end
      end
    end
  end

  describe '.evolve' do

    let(:binary) do
      described_class.new('testing', :md5)
    end

    let(:evolved) do
      described_class.evolve(binary)
    end

    it 'returns the binary' do
      expect(evolved).to eq(binary)
    end
  end

  describe '.mongoize' do

    let(:binary) do
      described_class.new('testing', :md5)
    end

    let(:mongoized) do
      described_class.mongoize(binary)
    end

    it 'returns the binary' do
      expect(mongoized).to eq(binary)
    end
  end
end
