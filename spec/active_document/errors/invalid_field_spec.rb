# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Errors::InvalidField do

  describe '#message' do

    module MyModule
      def crazy_method
        self
      end
    end

    before do
      Object.include MyModule
    end

    let(:error) do
      described_class.new(Person, :crazy_method, :crazy_method)
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        "Defining a field named 'crazy_method' is not allowed."
      )
    end

    it 'contains the summary in the message' do
      expect(error.message).to include(
        "Defining this field would override the method 'crazy_method'"
      )
    end

    it 'contains the resolution in the message' do
      expect(error.message).to include(
        'Use ActiveDocument.destructive_fields to see what names are not allowed'
      )
    end
  end
end
