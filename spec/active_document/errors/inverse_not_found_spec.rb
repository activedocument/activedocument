# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Errors::InverseNotFound do

  describe '#message' do

    let(:error) do
      described_class.new('Town', :citizens, 'Person', :town_id)
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'When adding a(n) Person to Town#citizens, ActiveDocument could not'
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        'hen adding a document to an association, ActiveDocument attempts to link'
      )
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include(
        'If an inverse is not required, like a belongs_to or'
      )
    end
  end
end
