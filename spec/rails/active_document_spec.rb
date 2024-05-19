# frozen_string_literal: true

require 'spec_helper'
require 'support/feature_sandbox'

describe 'Rails::ActiveDocument' do
  let(:model_root) do
    File.absolute_path(
      File.join(
        File.dirname(__FILE__),
        '../support/models/sandbox'
      )
    )
  end

  around do |example|
    FeatureSandbox.quarantine do
      require 'rails/active_document'
      $LOAD_PATH.push(model_root)
      example.run
    end
  end

  describe '.preload_models' do
    let(:app) { double(config: config) }
    let(:config) { double(paths: paths) }
    let(:paths) { { 'app/models' => path } }
    let(:path) { double(expanded: [model_root]) }

    before { Rails::ActiveDocument.preload_models(app) }

    context 'when preload models config is false' do
      config_override :preload_models, false

      it 'does not load any models' do
        expect(defined?(SandboxMessage)).to be_nil
        expect(defined?(SandboxUser)).to be_nil
        expect(defined?(SandboxComment)).to be_nil
      end
    end

    context 'when preload models config is true' do
      config_override :preload_models, true

      context 'when all models are in the models directory' do
        it 'requires the models' do
          expect(SandboxMessage.ancestors).to include(ActiveDocument::Document)
          expect(SandboxUser.ancestors).to include(ActiveDocument::Document)
          expect(SandboxComment.ancestors).to include(ActiveDocument::Document)
        end
      end
    end
  end
end
