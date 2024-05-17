# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Errors::NoClientHosts do

  describe '#message' do

    let(:error) do
      described_class.new(:analytics, { database: 'active_document_test' })
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'No hosts provided for client configuration: :analytics.'
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        'Each client configuration must provide hosts so ActiveDocument'
      )
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include(
        'If configuring via a active_document.yml, ensure that within your :analytics'
      )
    end
  end
end
