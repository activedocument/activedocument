# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Criteria::Marshalable do
  describe 'Marshal.dump' do

    let(:criteria) do
      Band.where(name: 'Depeche Mode')
    end

    it 'does not error' do
      expect do
        Marshal.dump(criteria)
      end.to_not raise_error
    end
  end

  describe 'Marshal.load' do

    let(:criteria) do
      Band.where(name: 'Depeche Mode')
    end

    it 'loads the proper attributes' do
      expect(Marshal.load(Marshal.dump(criteria))).to eq(criteria)
    end
  end
end
