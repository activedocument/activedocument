# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Extensions::String do

  describe '#collectionize' do

    context 'when class is namepaced' do

      module Medical
        class Patient
          include ActiveDocument::Document
        end
      end

      it 'returns an underscored table-ized name' do
        expect(Medical::Patient.name.collectionize).to eq('medical_patients')
      end
    end

    context 'when class is not namespaced' do

      it 'returns an underscored table-ized name' do
        expect(MixedDrink.name.collectionize).to eq('mixed_drinks')
      end
    end
  end

  %i[mongoize demongoize].each do |method|

    describe ".#{method}" do

      context 'when the object is not a string' do

        it 'returns the string' do
          expect(String.send(method, :test)).to eq('test')
        end
      end

      context 'when the object is nil' do

        it 'returns nil' do
          expect(String.send(method, nil)).to be_nil
        end
      end
    end
  end

  describe '#mongoize' do

    it 'returns self' do
      expect('test'.mongoize).to eq('test')
    end
  end

  describe '#reader' do

    context 'when string is a reader' do

      it 'returns self' do
        expect('attribute'.reader).to eq('attribute')
      end
    end

    context 'when string is a writer' do

      it 'returns the reader' do
        expect('attribute='.reader).to eq('attribute')
      end
    end

    context 'when the string is before_type_cast' do

      it 'returns the reader' do
        expect('attribute_before_type_cast'.reader).to eq('attribute')
      end
    end
  end

  describe '#numeric?' do

    context 'when the string is an integer' do

      it 'returns true' do
        expect('1234'.numeric?).to be(true)
      end
    end

    context 'when string is a float' do

      it 'returns true' do
        expect('1234.123'.numeric?).to be(true)
      end
    end

    context 'when the string is has exponents' do

      it 'returns true' do
        expect('1234.123123E4'.numeric?).to be(true)
      end
    end

    context 'when the string is non numeric' do

      it 'returns false' do
        expect('blah'.numeric?).to be(false)
      end
    end

    context 'when the string is NaN' do

      it 'returns true' do
        expect('NaN'.numeric?).to be(true)
      end
    end

    context 'when the string is NaN and junk in front' do

      it 'returns false' do
        expect("a\nNaN".numeric?).to be(false)
      end
    end

    context 'when the string is NaN and whitespace at end' do

      it 'returns false' do
        expect("NaN\n".numeric?).to be(false)
      end
    end

    context 'when the string is Infinity' do

      it 'returns true' do
        expect('Infinity'.numeric?).to be(true)
      end
    end

    context 'when the string contains Infinity and junk in front' do

      it 'returns false' do
        expect("a\nInfinity".numeric?).to be(false)
      end
    end

    context 'when the string contains Infinity and whitespace at end' do

      it 'returns false' do
        expect("Infinity\n".numeric?).to be(false)
      end
    end

    context 'when the string is -Infinity' do

      it 'returns true' do
        expect('-Infinity'.numeric?).to be(true)
      end
    end
  end

  describe '#singularize' do

    context 'when string is address' do

      it 'returns address' do
        expect('address'.singularize).to eq('address')
      end
    end

    context 'when string is address_profiles' do

      it 'returns address_profile' do
        expect('address_profiles'.singularize).to eq('address_profile')
      end
    end
  end

  describe '#writer?' do

    context 'when string is a reader' do

      it 'returns false' do
        expect('attribute'.writer?).to be false
      end
    end

    context 'when string is a writer' do

      it 'returns true' do
        expect('attribute='.writer?).to be true
      end
    end
  end

  describe '#before_type_cast?' do

    context 'when string is a reader' do

      it 'returns false' do
        expect('attribute'.before_type_cast?).to be false
      end
    end

    context 'when string is before_type_cast' do

      it 'returns true' do
        expect('attribute_before_type_cast'.before_type_cast?).to be true
      end
    end
  end

end
