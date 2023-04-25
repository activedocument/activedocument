# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mongoid::BundleChecker do
  subject(:check_mongoid) { described_class.check_gem_absent!('mongoid') }

  context 'when mongoid gem is not present' do
    it 'does not raise an error' do
      expect { check_mongoid }.to_not raise_error
    end
  end

  context 'when mongoid gem is present' do
    let(:mongoid_spec) { instance_double(Gem::Specification, name: 'mongoid') }

    before do
      allow(Gem::Specification).to receive(:find_by_name).with('mongoid').and_return(mongoid_spec)
    end

    it 'raises an error' do
      expect { check_mongoid }.to raise_error(Mongoid::Errors::GemConflict,
                                              /Gem 'mongoid-ultra' conflicts with gem 'mongoid'/)
    end
  end
end
