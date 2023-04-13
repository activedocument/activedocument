# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Errors::GemConflict do

  describe '#message' do
    let(:error) do
      described_class.new('foo')
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        "Gem 'mongoid-ultra' conflicts with gem 'foo'."
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        "Gems 'mongoid-ultra' and 'foo' cannot be used in the same project."
      )
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include(
        "Ensure that 'foo' gem is not loaded into your project. Check"
      )
    end
  end
end
