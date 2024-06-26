# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Errors::NoMetadata do

  describe '#message' do

    let(:error) do
      described_class.new(Address)
    end

    it 'contains the problem in the message' do
      expect(error.message).to include('Metadata not found for document of type Address.')
    end

    it 'contains the summary in the message' do
      expect(error.message).to include('ActiveDocument sets the metadata of an association on the')
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include('Ensure that your associations on the Address model')
    end
  end
end
