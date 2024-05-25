# frozen_string_literal: true

require 'spec_helper'

describe NilClass do

  describe '#__evolve_date__' do

    it 'returns nil' do
      expect(nil.__evolve_date__).to be_nil
    end
  end

  describe '#__evolve_time__' do

    it 'returns nil' do
      expect(nil.__evolve_time__).to be_nil
    end
  end
end
