# frozen_string_literal: true

require 'spec_helper'

describe ActiveModel::Validations::NumericalityValidator do

  describe '#validate_each' do

    before(:all) do
      class TestModel
        include ActiveDocument::Document
        field :amount, type: :big_decimal
        validates_numericality_of :amount, allow_blank: false
      end
    end

    after(:all) do
      Object.send(:remove_const, :TestModel)
    end

    context 'when the value is non numeric' do

      let(:model) do
        TestModel.new(amount: 'asdf')
      end

      it 'returns false' do
        expect(model).to_not be_valid
      end
    end
  end
end
