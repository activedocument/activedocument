# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveDocument::BundleChecker do
  subject(:check_active_document) { described_class.check_gem_absent!('active_document') }

  context 'when active_document gem is not present' do
    it 'does not raise an error' do
      expect { check_active_document }.to_not raise_error
    end
  end

  context 'when active_document gem is present' do
    let(:active_document_spec) { instance_double(Gem::Specification, name: 'active_document') }

    before do
      allow(Gem::Specification).to receive(:find_by_name).with('active_document').and_return(active_document_spec)
    end

    it 'raises an error' do
      expect { check_active_document }.to raise_error(ActiveDocument::Errors::GemConflict,
                                              /Gem 'active_document-ultra' conflicts with gem 'active_document'/)
    end
  end
end
