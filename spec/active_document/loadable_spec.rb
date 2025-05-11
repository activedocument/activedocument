# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Loadable do
  let(:lib_dir) { Pathname.new('../../lib').realpath(__dir__) }

  shared_context 'with ignore_patterns' do
    around do |example|
      saved = ActiveDocument.ignore_patterns
      ActiveDocument.ignore_patterns = ignore_patterns
      example.run
    ensure
      ActiveDocument.ignore_patterns = saved
    end
  end

  describe '#ignore_patterns' do
    context 'when not explicitly set' do
      it 'equals the default list of ignore patterns' do
        expect(ActiveDocument.ignore_patterns).to eq ActiveDocument::Loadable::DEFAULT_IGNORE_PATTERNS
      end
    end

    context 'when explicitly set' do
      include_context 'with ignore_patterns'

      let(:ignore_patterns) { %w[pattern1 pattern2] }

      it 'equals the list of specified patterns' do
        expect(ActiveDocument.ignore_patterns).to eq ignore_patterns
      end
    end
  end

  describe '#files_under_path' do
    let(:results) { ActiveDocument.files_under_path(lib_dir) }

    include_context 'with ignore_patterns'

    context 'when ignore_patterns is empty' do
      let(:ignore_patterns) { [] }

      it 'returns all ruby files' do
        expect(results.length).to be > 10 # should be a bunch of them
        expect(results).to include('rails/mongoid')
      end
    end

    context 'when ignore_patterns is not empty' do
      let(:ignore_patterns) { %w[*/rails/*] }

      it 'omits the ignored paths' do
        expect(results.length).to be > 10 # should be a bunch of them
        expect(results).to_not include('rails/mongoid')
      end
    end
  end

  describe '#files_under_paths' do
    let(:paths) { [lib_dir.join('mongoid'), lib_dir.join('rails')] }
    let(:results) { ActiveDocument.files_under_paths(paths) }

    include_context 'with ignore_patterns'

    context 'when ignore_patterns is empty' do
      let(:ignore_patterns) { [] }

      it 'returns all ruby files' do
        expect(results.length).to be > 10 # should be a bunch
        expect(results).to include('generators/mongoid/model/model_generator')
        expect(results).to include('fields/encrypted')
      end
    end

    context 'when ignore_patterns is not empty' do
      let(:ignore_patterns) { %w[*/model/* */fields/*] }

      it 'returns all ruby files' do
        expect(results.length).to be > 10 # should be a bunch
        expect(results).to_not include('generators/mongoid/model/model_generator')
        expect(results).to_not include('fields/encrypted')
      end
    end
  end
end
