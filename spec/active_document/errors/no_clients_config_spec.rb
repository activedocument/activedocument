# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Errors::NoClientsConfig do

  describe '#message' do

    let(:error) do
      described_class.new
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'No clients configuration provided.'
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        "ActiveDocument's configuration requires that you provide details"
      )
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include(
        'Double check your active_document.yml to make sure that you have'
      )
    end
  end
end
