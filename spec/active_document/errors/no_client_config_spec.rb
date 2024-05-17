# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Errors::NoClientConfig do

  describe '#message' do

    let(:error) do
      described_class.new(:analytics)
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        "No configuration could be found for a client named 'analytics'."
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        'When attempting to create the new client, ActiveDocument could not find a client'
      )
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include(
        'Double check your activedocument.yml to make sure under the clients'
      )
    end
  end
end
