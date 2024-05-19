# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Errors::NoClientDatabase do

  describe '#message' do

    let(:error) do
      described_class.new(:analytics, { hosts: ['127.0.0.1:27017'] })
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'No database provided for client configuration: :analytics.'
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        'Each client configuration must provide a database so ActiveDocument'
      )
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include(
        'If configuring via a active_document.yml, ensure that within your :analytics'
      )
    end
  end
end
