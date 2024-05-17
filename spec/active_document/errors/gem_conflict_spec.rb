# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Errors::GemConflict do

  describe '#message' do
    let(:error) do
      described_class.new('foo')
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        "Gem 'active_document-ultra' conflicts with gem 'foo'."
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        "Gems 'active_document-ultra' and 'foo' cannot be used in the same project."
      )
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include(
        "Ensure that 'foo' gem is not loaded into your project. Check"
      )
    end
  end
end
