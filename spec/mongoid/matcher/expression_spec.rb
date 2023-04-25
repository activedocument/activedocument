# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Matcher::Expression do

  describe '#matches?' do
    subject { described_class.matches?(doc, expr) }

    let(:doc) do
      Person.new({
        title: 'Sir',
        name: { given: 'Bob' }
      })
    end

    context 'when expression matches field exactly' do
      let(:expr) { { title: 'Sir' } }

      it { is_expected.to be true }
    end

    context 'when expression contains a $comment' do
      let(:expr) { { title: 'Sir', '$comment' => 'hello' } }

      it 'ignores the $comment' do
        expect(subject).to be true
      end
    end
  end
end
