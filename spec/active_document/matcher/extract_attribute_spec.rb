# frozen_string_literal: true

require 'spec_helper'

describe 'Matcher.extract_attribute' do
  Dir[File.join(File.dirname(__FILE__), 'extract_attribute_data', '*.yml')].each do |path|
    context File.basename(path) do
      specs = YAML.safe_load_file(path, aliases: true)

      specs.each do |spec|
        context spec['name'] do

          pending spec['pending'].to_s if spec['pending']

          let(:document) do
            spec['document']
          end

          let(:key) { spec['key'] }

          let(:actual) do
            ActiveDocument::Matcher.extract_attribute(document, key)
          end

          let(:expected) { spec.fetch('result') }

          it 'has the expected result' do
            expect(actual).to eq(expected)
          end
        end
      end
    end
  end
end
