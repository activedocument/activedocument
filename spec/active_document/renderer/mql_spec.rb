# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Renderer::MQL do
  include ActiveDocument::AST

  let(:tree) { nil }

  describe '.render' do
    subject(:result) { described_class.render(tree) }

    context 'when tree is nil' do
      let(:tree) { nil }

      it { is_expected.to be_nil }
    end

    context 'when tree is not an AST::Node' do
      let(:tree) { [] }

      it { is_expected.to be_nil }
    end

    context 'when tree is an empty AST::Node' do
      context 'when node is field_operator' do
        let(:tree) { Eq(nil, nil) }

        it { is_expected.to be_nil }
      end

      context 'when node is logical operator' do
        let(:tree) { And([]) }

        it { is_expected.to be_nil }
      end
    end

    context 'when tree is a non-empty AST::Node' do
      context 'with single operator' do
        let(:tree) { Eq('age', 0) }

        it { is_expected.to eq('age' => { '$eq' => 0 }) }
      end

      context 'with ANDs' do
        context 'with two different operators' do
          let(:tree) do
            And(
              Gt('age', 1),
              Eq('age', 0)
            )
          end

          it {
            is_expected.to eq(
              { '$and' => [
                { 'age' => { '$gt' => 1 } },
                { 'age' => { '$eq' => 0 } }
              ] }
            )
          }
        end

        context 'with same operator twice' do
          let(:tree) do
            And(
              Eq('age', 1),
              Eq('age', 0)
            )
          end

          it {
            is_expected.to eq(
              { '$and' => [
                { 'age' => { '$eq' => 1 } },
                { 'age' => { '$eq' => 0 } }
              ] }
            )
          }
        end

        context 'with many different operators' do
          let(:tree) do
            And(
              And(
                And(
                  AnyIn('age', [2, 1, 0, -1, -2]),
                  Lte('age', -1)
                ),
                Gt('age', 1)
              ),
              Eq('age', 0)
            )
          end

          it {
            is_expected.to eq(
              { '$and' => [
                { '$and' => [
                  { '$and' => [
                    { 'age' => { '$in' => [2, 1, 0, -1, -2] } },
                    { 'age' => { '$lte' => -1 } }
                  ] },
                  { 'age' => { '$gt' => 1 } }
                ] },
                { 'age' => { '$eq' => 0 } }
              ] }
            )
          }
        end

        context 'with many different operators with repetitions' do
          let(:tree) do
            And(
              And(
                And(
                  And(
                    And(
                      Gt('age', 10),
                      Eq('age', -10)
                    ),
                    AnyIn('age', [2, 1, 0, -1, -2])
                  ),
                  Lte('age', -1)
                ),
                Gt('age', 1)
              ),
              Eq('age', 0)
            )
          end

          it {
            is_expected.to eq(
              { '$and' => [
                { '$and' => [
                  { '$and' => [
                    { '$and' => [
                      { '$and' => [
                        { 'age' => { '$gt' => 10 } },
                        { 'age' => { '$eq' => -10 } }
                      ] },
                      { 'age' => { '$in' => [2, 1, 0, -1, -2] } }
                    ] },
                    { 'age' => { '$lte' => -1 } }
                  ] },
                  { 'age' => { '$gt' => 1 } }
                ] },
                { 'age' => { '$eq' => 0 } }
              ] }
            )
          }
        end
      end

      context 'with multiple logical operators' do
        let(:tree) { And(Or(Eq('name', 'John'), Eq('name', 'Jane')), Eq('age', 0)) }

        it {
          is_expected.to eq(
            { '$and' => [
              { '$or' => [
                { 'name' => { '$eq' => 'John' } },
                { 'name' => { '$eq' => 'Jane' } }
              ] },
              { 'age' => { '$eq' => 0 } }
            ] }
          )
        }
      end
    end
  end
end
