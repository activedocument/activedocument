# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument do

  describe '::VERSION' do
    it { expect(ActiveDocument::VERSION).to match(/\A\d+\.\d+\.\d+(?:\.\w*\d+)?\z/) }
  end

  describe '::GEM_NAME' do
    it { expect(ActiveDocument::GEM_NAME).to eq('active_document') }
  end
end
