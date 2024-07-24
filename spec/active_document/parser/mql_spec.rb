# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Parser::MQL do
  include ActiveDocument::AST

  let(:mql) { nil }

  describe '.parse' do
    context 'when data unsupported' do
      subject(:result) { described_class.parse(mql) }

      context 'when data is nil' do
        let(:mql) { nil }

        it { is_expected.to be_nil }
      end

      context 'when data is not a hash' do
        let(:mql) { [] }

        it { is_expected.to be_nil }
      end

      context 'when data is an empty hash' do
        let(:mql) { {} }

        it { is_expected.to be_nil }
      end

      context 'when data has unsupported klass' do
        let(:custom_klass) { Struct.new(:year, :month, :day) }
        let(:custom_value) { custom_klass.new(2000, 1, 1) }

        context 'when plain value' do
          let(:mql) { { 'age' => { '$eq' => custom_value } } }

          it { expect { result }.to raise_error(RuntimeError) }
        end

        context 'when item in an array' do
          let(:mql) { { 'age' => { '$in' => [1, custom_value, 99] } } }

          it { expect { result }.to raise_error(RuntimeError) }
        end

      end
    end

    context 'when data supported' do
      subject { described_class.parse(mql) }

      let(:criteria) { Person.where }
      let(:mql) { criteria.selector_render }

      context 'with single field operator' do
        context 'with eq' do
          let(:criteria) { Person.where(age: { '$eq' => 0 }) }

          it { is_expected.to eq(Eq('age', 0)) }
        end

        context 'with gt' do
          let(:criteria) { Person.where(age: { '$gt' => 0 }) }

          it { is_expected.to eq(Gt('age', 0)) }
        end

        context 'with gte' do
          let(:criteria) { Person.where(age: { '$gte' => 0 }) }

          it { is_expected.to eq(Gte('age', 0)) }
        end

        context 'with in' do
          let(:criteria) { Person.where(age: { '$in' => [0, 1, 2] }) }

          it { is_expected.to eq(AnyIn('age', [0, 1, 2])) }
        end

        context 'with lt' do
          let(:criteria) { Person.where(age: { '$lt' => 0 }) }

          it { is_expected.to eq(Lt('age', 0)) }
        end

        context 'with lte' do
          let(:criteria) { Person.where(age: { '$lte' => 0 }) }

          it { is_expected.to eq(Lte('age', 0)) }
        end

        context 'with ne' do
          let(:criteria) { Person.where(age: { '$ne' => 0 }) }

          it { is_expected.to eq(NotEq('age', 0)) }
        end

        context 'with nin' do
          let(:criteria) { Person.where(age: { '$nin' => [0, 1, 2] }) }

          it { is_expected.to eq(NotIn('age', [0, 1, 2])) }
        end
      end

      context 'with single logical operator' do
        context 'with and' do
          let(:criteria) { Person.where('$and' => [{ age: { '$eq' => 0 } }, { age: { '$gt' => 1 } }]) }

          it {
            is_expected.to eq(
              And(
                Gt('age', 1),
                Eq('age', 0)
              )
            )
          }
        end

        context 'with nor' do
          let(:criteria) { Person.where('$nor' => [{ age: { '$eq' => 0 } }, { age: { '$gt' => 1 } }]) }

          it {
            is_expected.to eq(
              Nor(
                Gt('age', 1),
                Eq('age', 0)
              )
            )
          }
        end

        context 'with not' do
          let(:criteria) { Person.where('$not' => { age: { '$eq' => 0 } }) }

          it { is_expected.to eq(Not(Eq('age', 0))) }
        end

        context 'with or' do
          let(:criteria) { Person.where('$or' => [{ age: { '$eq' => 0 } }, { age: { '$gt' => 1 } }]) }

          it {
            is_expected.to eq(
              Or(
                Gt('age', 1),
                Eq('age', 0)
              )
            )
          }
        end
      end

      context 'with two different operators' do
        let(:criteria) { Person.where(age: { '$eq' => 0 }).where(age: { '$gt' => 1 }) }

        it {
          is_expected.to eq(
            And(
              Gt('age', 1),
              Eq('age', 0)
            )
          )
        }
      end

      context 'with same operator twice' do
        let(:criteria) { Person.where(age: { '$eq' => 0 }).where(age: { '$eq' => 1 }) }

        it {
          is_expected.to eq(
            And(
              Eq('age', 1),
              Eq('age', 0)
            )
          )
        }
      end

      context 'with many different operators' do
        let(:criteria) { Person.where(age: { '$eq' => 0 }).where(age: { '$gt' => 1 }).where(age: { '$lte' => -1 }).where(age: { '$in' => [2, 1, 0, -1, -2] }) }

        it {
          is_expected.to eq(
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
          )
        }
      end

      context 'with many different operators with repetitions' do
        let(:criteria) { Person.where(age: { '$eq' => 0 }).where(age: { '$gt' => 1 }).where(age: { '$lte' => -1 }).where(age: { '$in' => [2, 1, 0, -1, -2] }).where(age: { '$eq' => -10 }).where(age: { '$gt' => 10 }) }

        it {
          is_expected.to eq(
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
          )
        }
      end

      context 'with or' do
        context 'with single operator' do
          let(:mql) { { '$or' => [{ 'age' => { '$eq' => 0 } }] } }

          it { is_expected.to eq(Eq('age', 0)) }
        end

        context 'with two different operators' do
          let(:mql) { { '$or' => [{ 'age' => { '$eq' => 0 } }, { 'age' => { '$gt' => 1 } }] } }

          it {
            is_expected.to eq(
              Or(
                Gt('age', 1),
                Eq('age', 0)
              )
            )
          }
        end

        context 'with same operator twice' do
          let(:mql) { { '$or' => [{ 'age' => { '$eq' => 0 } }, { 'age' => { '$eq' => 1 } }] } }

          it {
            is_expected.to eq(
              Or(
                Eq('age', 1),
                Eq('age', 0)
              )
            )
          }
        end

        context 'with many different operators' do
          let(:mql) { { '$or' => [{ 'age' => { '$eq' => 0 } }, { 'age' => { '$gt' => 1 } }, { 'age' => { '$lte' => -1 } }, { 'age' => { '$in' => [2, 1, 0, -1, -2] } }] } }

          it {
            is_expected.to eq(
              Or(
                Or(
                  Or(
                    AnyIn('age', [2, 1, 0, -1, -2]),
                    Lte('age', -1)
                  ),
                  Gt('age', 1)
                ),
                Eq('age', 0)
              )
            )
          }
        end

        context 'with many different operators with repetitions' do
          let(:mql) { { '$or' => [{ 'age' => { '$eq' => 0 } }, { 'age' => { '$gt' => 1 } }, { 'age' => { '$lte' => -1 } }, { 'age' => { '$in' => [2, 1, 0, -1, -2] } }, { 'age' => { '$eq' => -10 } }, { 'age' => { '$gt' => 10 } }] } }

          it {
            is_expected.to eq(
              Or(
                Or(
                  Or(
                    Or(
                      Or(
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
            )
          }
        end
      end
    end
  end

end
