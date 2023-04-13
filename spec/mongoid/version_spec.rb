# frozen_string_literal: true

require 'spec_helper'

describe Mongoid do

  describe '::VERSION' do
    it { expect(Mongoid::VERSION).to match(/\A\d+\.\d+\.\d+\.\d+(?:\.\w+\d+)?\z/) }
  end

  describe '::ULTRA' do
    it { expect(Mongoid::ULTRA).to be true }
  end

  describe '::GEM_NAME' do
    it { expect(Mongoid::GEM_NAME).to eq('mongoid-ultra') }
  end
end
