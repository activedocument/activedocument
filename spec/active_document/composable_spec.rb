# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Composable do

  describe '.prohibited_methods' do

    let(:methods) do
      described_class.prohibited_methods
    end

    ActiveDocument::Composable::MODULES.each do |mod|

      context "when checking in #{mod}" do

        mod.instance_methods.each do |method|

          it "includes #{method}" do
            expect(methods).to include(method.to_sym)
          end
        end
      end
    end

    ActiveDocument::Composable::RESERVED_METHOD_NAMES.each do |name|

      it "includes the method names #{name}" do
        expect(methods).to include(name)
      end
    end
  end
end
