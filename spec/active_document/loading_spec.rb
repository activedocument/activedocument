# frozen_string_literal: true

require 'ostruct'
require 'spec_helper'
require 'support/feature_sandbox'

describe ActiveDocument::Loadable do
  let(:model_root) do
    File.absolute_path(
      File.join(
        File.dirname(__FILE__),
        '../support/models/sandbox'
      )
    )
  end

  let(:app_models_root) { File.join(model_root, 'app/models') }
  let(:lib_models_root) { File.join(model_root, 'lib/models') }

  describe '#model_paths' do
    # reset model_paths to the default value
    before { ActiveDocument.model_paths = nil }

    context 'when Rails is defined' do
      around do |example|
        FeatureSandbox.quarantine do
          require 'support/rails_mock'
          require 'rails/active_document'
          example.run
        end
      end

      it "returns Rails' app/models paths" do
        expect(ActiveDocument.model_paths).to eq %w[app/models]
      end
    end

    context 'when Rails is not defined' do
      it "returns ActiveDocument's default model paths" do
        expect(ActiveDocument.model_paths).to eq %w[./app/models ./lib/models]
      end
    end

    context 'when explicitly set' do
      before { ActiveDocument.model_paths = %w[/infra/models] }

      it 'returns the given value' do
        expect(ActiveDocument.model_paths).to eq %w[/infra/models]
      end
    end
  end

  describe '#load_models' do
    around do |example|
      FeatureSandbox.quarantine do
        ActiveDocument.model_paths = nil
        example.run
      end
    end

    context 'when using default paths' do
      around do |example|
        $LOAD_PATH.push app_models_root, lib_models_root

        Dir.chdir(model_root) do
          ActiveDocument.load_models
          example.run
        end
      end

      it 'finds models in the default paths' do
        expect(defined?(AppModelsMessage)).to eq 'constant'
        expect(defined?(LibModelsMessage)).to eq 'constant'
        expect(defined?(SandboxMessage)).to be_nil
      end
    end

    context 'when using custom model_paths' do
      before do
        ActiveDocument.model_paths = [app_models_root]
        $LOAD_PATH.push app_models_root
        ActiveDocument.load_models
      end

      it 'finds models in the specified paths' do
        expect(defined?(AppModelsMessage)).to eq 'constant'
        expect(defined?(LibModelsMessage)).to be_nil
        expect(defined?(SandboxMessage)).to be_nil
      end
    end

    context 'when passing paths directly' do
      before do
        $LOAD_PATH.push model_root
        ActiveDocument.load_models([model_root])
      end

      it 'finds models in the specified paths' do
        expect(defined?(AppModelsMessage)).to eq 'constant'
        expect(defined?(LibModelsMessage)).to eq 'constant'
        expect(defined?(SandboxMessage)).to eq 'constant'
        expect(defined?(SandboxComment)).to eq 'constant'
      end
    end
  end
end

module ActiveDocument
  module Loadable
    module RailsApplication
      attr_accessor :application
    end
  end
end
