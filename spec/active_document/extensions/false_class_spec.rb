# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Extensions::FalseClass do

  describe '#is_a?' do

    context 'when provided a Boolean' do

      it 'returns true' do
        expect(false.is_a?(ActiveDocument::Boolean)).to be true
      end
    end

    context 'when provided a FalseClass' do

      it 'returns true' do
        expect(false.is_a?(FalseClass)).to be true
      end
    end

    context 'when provided a TrueClass' do

      it 'returns false' do
        expect(false.is_a?(TrueClass)).to be false
      end
    end

    context 'when provided an invalid class' do

      it 'returns false' do
        expect(false.is_a?(String)).to be false
      end
    end
  end
end
