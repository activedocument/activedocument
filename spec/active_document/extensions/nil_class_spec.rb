# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Extensions::NilClass do

  describe '#collectionize' do

    it "returns ''" do
      expect(nil.collectionize).to be_empty
    end
  end
end