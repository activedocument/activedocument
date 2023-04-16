# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Matcher::Expression do

  describe '#matches?' do
    let(:doc) do
      Person.new({
        title: 'Sir',
        name: { given: 'Bob' }
      })
    end
    subject { described_class.matches?(doc, expr) }

    context 'when expression matches field exactly' do
      let(:expr) { { title: 'Sir' } }

      it { is_expected.to be true }
    end

    context 'when expression contains a $comment' do
      let(:expr) { { title: 'Sir', '$comment' => 'hello' } }

      it 'ignores the $comment' do
        is_expected.to be true
      end
    end
  end
end
