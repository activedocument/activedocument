# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Extensions::Integer do

  let(:number) do
    118347652312341
  end

  %i[mongoize demongoize].each do |method|

    describe ".#{method}" do

      context 'when the value is a number' do

        context 'when the value is an integer' do

          context 'when the value is small' do

            it 'returns the integer' do
              expect(Integer.send(method, 3)).to eq(3)
            end
          end

          context 'when the value is large' do

            it 'returns the integer' do
              expect(Integer.send(method, 1024**2).to_s).to eq('1048576')
            end
          end
        end

        context 'when the value is a decimal' do

          it 'casts to integer' do
            expect(Integer.send(method, 2.5)).to eq(2)
          end
        end

        context 'when the value is floating point zero' do

          it 'returns the integer zero' do
            expect(Integer.send(method, 0.00000)).to eq(0)
          end
        end

        context 'when the value is a floating point integer' do

          it 'returns the integer number' do
            expect(Integer.send(method, 4.00000)).to eq(4)
          end
        end

        context 'when the value has leading zeros' do

          it 'returns the stripped integer' do
            expect(Integer.send(method, '000011')).to eq(11)
          end
        end
      end

      context 'when the string is not a number' do

        context 'when the string is non numerical' do

          it 'returns nil' do
            expect(Integer.send(method, 'foo')).to be_nil
          end
        end

        context 'when the string starts with a number' do

          it 'returns nil' do
            expect(Integer.send(method, '42bogus')).to be_nil
          end
        end

        context 'when the string is empty' do

          it 'returns nil' do
            expect(Integer.send(method, '')).to be_nil
          end
        end

        context 'when the string is nil' do

          it 'returns nil' do
            expect(Integer.send(method, nil)).to be_nil
          end
        end

        context 'when giving an object that is castable to an Integer' do

          it 'returns the integer value' do
            expect(Integer.send(method, 2.hours)).to eq(7200)
          end
        end
      end
    end
  end

  describe '#mongoize' do

    it 'returns self' do
      expect(number.mongoize).to eq(number)
    end
  end

  describe '#numeric?' do

    it 'returns true' do
      expect(number.numeric?).to be(true)
    end
  end
end
