# frozen_string_literal: true

require 'spec_helper'
require_relative './selectable_shared_examples'

class FieldWithSerializer
  def evolve(object)
    Integer.evolve(object)
  end

  def localized?
    false
  end
end

describe ActiveDocument::Criteria::Queryable::Selectable do

  let(:query) do
    ActiveDocument::Query.new('id' => '_id')
  end

  shared_examples_for 'ands the arguments' do

    context 'when the field is not aliased' do
      let(:selection) do
        query.send(query_method, first: [1, 2]).send(query_method, first: [3, 4])
      end

      it 'combines the conditions with $and' do
        expect(selection.selector).to eq({
          'first' => { operator => [1, 2] },
          '$and' => [{ 'first' => { operator => [3, 4] } }]
        })
      end

      it_behaves_like 'returns a cloned query'
    end

    context 'when the field is aliased' do
      let(:selection) do
        query.send(query_method, id: [1, 2]).send(query_method, _id: [3, 4])
      end

      it 'combines the conditions with $and' do
        expect(selection.selector).to eq({
          '_id' => { operator => [1, 2] },
          '$and' => [{ '_id' => { operator => [3, 4] } }]
        })
      end

      it_behaves_like 'returns a cloned query'
    end

    context 'when the field uses a serializer' do
      let(:query) do
        ActiveDocument::Query.new({}, { 'field' => FieldWithSerializer.new })
      end

      let(:selection) do
        query.send(query_method, field: %w[1 2]).send(query_method, field: %w[3 4])
      end

      it 'combines the conditions with $and' do
        expect(selection.selector).to eq({
          'field' => { operator => [1, 2] },
          '$and' => [{ 'field' => { operator => [3, 4] } }]
        })
      end

      it_behaves_like 'returns a cloned query'
    end

    context 'when operator value is a Range' do

      context 'when there is no existing condition' do
        let(:selection) do
          query.send(query_method, foo: 2..4)
        end

        it 'expands range to array' do
          expect(selection.selector).to eq({ 'foo' => { operator => [2, 3, 4] } })
        end
      end

      context 'when existing condition has Array value' do
        let(:selection) do
          query.send(query_method, foo: [1, 2, 3]).send(query_method, foo: 2..4)
        end

        it 'expands range to array' do
          expect(selection.selector).to eq({
            'foo' => { operator => [1, 2, 3] },
            '$and' => [{ 'foo' => { operator => [2, 3, 4] } }]
          })
        end
      end

      context 'when existing condition has Range value' do
        let(:selection) do
          query.send(query_method, foo: 1..3).send(query_method, foo: 2..4)
        end

        it 'expands range to array' do
          expect(selection.selector).to eq({
            'foo' => { operator => [1, 2, 3] },
            '$and' => [{ 'foo' => { operator => [2, 3, 4] } }]
          })
        end
      end
    end
  end

  # TODO: these should be added for in, nin, all
  # shared_examples_for 'intersects the arguments' do
  #
  #   context 'when the field is not aliased' do
  #     let(:selection) do
  #       query.send(query_method, first: [1, 2]).send(query_method, first: [2, 3])
  #     end
  #
  #     it 'intersects the conditions' do
  #       expect(selection.selector).to eq({ 'first' => { operator => [2] } })
  #     end
  #
  #     it_behaves_like 'returns a cloned query'
  #   end
  #
  #   context 'when the field is aliased' do
  #     let(:selection) do
  #       query.send(query_method, id: [1, 2]).send(query_method, _id: [2, 3])
  #     end
  #
  #     it 'intersects the conditions' do
  #       expect(selection.selector).to eq({ '_id' => { operator => [2] } })
  #     end
  #
  #     it_behaves_like 'returns a cloned query'
  #   end
  #
  #   context 'when the field uses a serializer' do
  #     let(:query) do
  #       ActiveDocument::Query.new({}, { 'field' => FieldWithSerializer.new })
  #     end
  #
  #     let(:selection) do
  #       query.send(query_method, field: %w[1 2]).send(query_method, field: %w[2 3])
  #     end
  #
  #     it 'intersects the conditions' do
  #       expect(selection.selector).to eq({ 'field' => { operator => [2] } })
  #     end
  #
  #     it_behaves_like 'returns a cloned query'
  #   end
  #
  #   context 'when operator value is a Range' do
  #
  #     context 'when there is no existing condition' do
  #       let(:selection) do
  #         query.send(query_method, foo: 2..4)
  #       end
  #
  #       it 'expands range to array' do
  #         expect(selection.selector).to eq({ 'foo' => { operator => [2, 3, 4] } })
  #       end
  #     end
  #
  #     context 'when existing condition has Array value' do
  #       let(:selection) do
  #         query.send(query_method, foo: [1, 2, 3]).send(query_method, foo: 2..4)
  #       end
  #
  #       it 'expands range to array' do
  #         expect(selection.selector).to eq({ 'foo' => { operator => [2, 3] } })
  #       end
  #     end
  #
  #     context 'when existing condition has Range value' do
  #       let(:selection) do
  #         query.send(query_method, foo: 1..3).send(query_method, foo: 2..4)
  #       end
  #
  #       it 'expands range to array' do
  #         expect(selection.selector).to eq({ 'foo' => { operator => [2, 3] } })
  #       end
  #     end
  #   end
  # end
  #
  # shared_examples_for 'unions the arguments' do
  #
  #   context 'when the field is not aliased' do
  #     let(:selection) do
  #       query.send(query_method, first: [1, 2]).union.send(query_method, first: [3, 4])
  #     end
  #
  #     it 'unions the conditions' do
  #       expect(selection.selector).to eq({ 'first' => { operator => [1, 2, 3, 4] } })
  #     end
  #
  #     it_behaves_like 'returns a cloned query'
  #   end
  #
  #   context 'when the field is aliased' do
  #     let(:selection) do
  #       query.send(query_method, _id: [1, 2]).union.send(query_method, id: [3, 4])
  #     end
  #
  #     it 'unions the conditions' do
  #       expect(selection.selector).to eq({ '_id' => { operator => [1, 2, 3, 4] } })
  #     end
  #
  #     it_behaves_like 'returns a cloned query'
  #   end
  #
  #   context 'when the field uses a serializer' do
  #     let(:query) do
  #       ActiveDocument::Query.new({}, { 'field' => FieldWithSerializer.new })
  #     end
  #
  #     let(:selection) do
  #       query.send(query_method, field: %w[1 2]).send(query_method, field: %w[2 3])
  #     end
  #
  #     it 'intersects the conditions' do
  #       expect(selection.selector).to eq({ 'field' => { operator => [1, 2, 3] } })
  #     end
  #
  #     it_behaves_like 'returns a cloned query'
  #   end
  #
  #   context 'when operator value is a Range' do
  #
  #     context 'when there is no existing condition' do
  #       let(:selection) do
  #         query.send(query_method, foo: 2..4)
  #       end
  #
  #       it 'expands range to array' do
  #         expect(selection.selector).to eq({ 'foo' => { operator => [2, 3, 4] } })
  #       end
  #     end
  #
  #     context 'when existing condition has Array value' do
  #
  #       let(:selection) do
  #         query.send(query_method, foo: [1, 2]).send(query_method, foo: 2..4)
  #       end
  #
  #       it 'expands range to array' do
  #         expect(selection.selector).to eq({ 'foo' => { operator => [1, 2, 3, 4] } })
  #       end
  #     end
  #
  #     context 'when existing condition has Range value' do
  #       let(:selection) do
  #         query.send(query_method, foo: 1..2).send(query_method, foo: 2..4)
  #       end
  #
  #       it 'expands range to array' do
  #         expect(selection.selector).to eq({ 'foo' => { operator => [1, 2, 3, 4] } })
  #       end
  #     end
  #   end
  # end
  #
  # shared_examples_for 'overrides the arguments' do
  #
  #   context 'when the field is not aliased' do
  #     let(:selection) do
  #       query.send(query_method, first: [1, 2]).override.send(query_method, first: [3, 4])
  #     end
  #
  #     it 'overwrites the first condition' do
  #       expect(selection.selector).to eq({ 'first' => { operator => [3, 4] } })
  #     end
  #
  #     it_behaves_like 'returns a cloned query'
  #   end
  #
  #   context 'when the field is aliased' do
  #     let(:selection) do
  #       query.send(query_method, _id: [1, 2]).override.send(query_method, id: [3, 4])
  #     end
  #
  #     it 'overwrites the first condition' do
  #       expect(selection.selector).to eq({ '_id' => { operator => [3, 4] } })
  #     end
  #
  #     it_behaves_like 'returns a cloned query'
  #   end
  #
  #   context 'when the field uses a serializer' do
  #     let(:query) do
  #       ActiveDocument::Query.new({}, { 'field' => FieldWithSerializer.new })
  #     end
  #
  #     let(:selection) do
  #       query.send(query_method, field: %w[1 2]).send(query_method, field: %w[2 3])
  #     end
  #
  #     it 'intersects the conditions' do
  #       expect(selection.selector).to eq({ 'field' => { operator => [2, 3] } })
  #     end
  #
  #     it_behaves_like 'returns a cloned query'
  #   end
  #
  #   context 'when operator value is a Range' do
  #
  #     context 'when there is no existing condition' do
  #
  #       let(:selection) do
  #         query.send(query_method, foo: 2..4)
  #       end
  #
  #       it 'expands range to array' do
  #         expect(selection.selector).to eq({ 'foo' => { operator => [2, 3, 4] } })
  #       end
  #     end
  #
  #     context 'when existing condition has Array value' do
  #       let(:selection) do
  #         query.send(query_method, foo: [1, 2]).send(query_method, foo: 2..4)
  #       end
  #
  #       it 'expands range to array' do
  #         expect(selection.selector).to eq({ 'foo' => { operator => [2, 3, 4] } })
  #       end
  #     end
  #
  #     context 'when existing condition has Range value' do
  #       let(:selection) do
  #         query.send(query_method, foo: 1..2).send(query_method, foo: 2..4)
  #       end
  #
  #       it 'expands range to array' do
  #         expect(selection.selector).to eq({ 'foo' => { operator => [2, 3, 4] } })
  #       end
  #     end
  #   end
  # end

  describe '#all' do
    let(:query_method) { :all }
    let(:operator) { '$all' }

    context 'when provided no criterion' do

      let(:selection) do
        query.all
      end

      it 'does not add any criterion' do
        expect(selection.selector).to eq({})
      end

      it 'returns the query' do
        expect(selection).to eq(query)
      end

      it 'returns a cloned query' do
        expect(selection).to_not equal(query)
      end
    end

    context 'when given an argument' do
      let(:selection) do
        query.all(field: [1, 2])
      end

      it { expect { selection.selector }.to raise_error(ArgumentError) }
    end
  end

  describe '#contains_all' do
    let(:query_method) { :contains_all }
    let(:operator) { '$all' }

    context 'when provided no criterion' do
      let(:selection) do
        query.contains_all
      end

      it { expect { selection.selector }.to raise_error(ActiveDocument::Errors::CriteriaArgumentRequired) }
    end

    it_behaves_like 'requires a non-nil argument'

    context 'when provided a single criterion' do

      context 'when no serializers are provided' do

        context 'when providing an array' do
          let(:selection) do
            query.contains_all(field: [1, 2])
          end

          it 'adds the $all selector' do
            expect(selection.selector).to eq({
                                               'field' => { '$all' => [1, 2] }
                                             })
          end

          it 'returns a cloned query' do
            expect(selection).to_not equal(query)
          end
        end

        context 'when providing a single value' do

          let(:selection) do
            query.contains_all(field: 1)
          end

          it 'adds the $all selector with wrapped value' do
            expect(selection.selector).to eq({
                                               'field' => { '$all' => [1] }
                                             })
          end

          it 'returns a cloned query' do
            expect(selection).to_not equal(query)
          end
        end
      end

      context 'when serializers are provided' do
        before(:all) do
          class Field
            def evolve(object)
              Integer.evolve(object)
            end

            def localized?
              false
            end
          end
        end

        after(:all) do
          Object.send(:remove_const, :Field)
        end

        let!(:query) do
          ActiveDocument::Query.new({}, { 'field' => Field.new })
        end

        context 'when providing an array' do

          let(:selection) do
            query.contains_all(field: %w[1 2])
          end

          it 'adds the $all selector' do
            expect(selection.selector).to eq({
                                               'field' => { '$all' => [1, 2] }
                                             })
          end

          it 'returns a cloned query' do
            expect(selection).to_not equal(query)
          end
        end

        context 'when providing a single value' do

          let(:selection) do
            query.contains_all(field: '1')
          end

          it 'adds the $all selector with wrapped value' do
            expect(selection.selector).to eq({
                                               'field' => { '$all' => [1] }
                                             })
          end

          it 'returns a cloned query' do
            expect(selection).to_not equal(query)
          end
        end
      end
    end

    context 'when provided multiple criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.contains_all(first: [1, 2], second: [3, 4])
        end

        it 'adds the $all selectors' do
          expect(selection.selector).to eq({
                                             'first' => { '$all' => [1, 2] },
                                             'second' => { '$all' => [3, 4] }
                                           })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining the criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.contains_all(first: [1, 2]).contains_all(second: [3, 4])
        end

        it 'adds the $all selectors' do
          expect(selection.selector).to eq({
            'first' => { '$all' => [1, 2] },
            'second' => { '$all' => [3, 4] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when the criterion are on the same field' do
        it_behaves_like 'ands the arguments'
        # TODO: it_behaves_like 'unions the arguments'
      end
    end
  end

  describe '#between' do
    let(:query_method) { :between }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a single range' do

      let(:selection) do
        query.between(field: 1..10)
      end

      it 'adds the $gte and $lte selectors' do
        expect(selection.selector).to eq({
          'field' => { '$gte' => 1, '$lte' => 10 }
        })
      end

      it 'returns a cloned query' do
        expect(selection).to_not equal(query)
      end
    end

    context 'when provided multiple ranges' do

      context 'when the ranges are on different fields' do

        let(:selection) do
          query.between(field: 1..10, key: 5..7)
        end

        it 'adds the $gte and $lte selectors' do
          expect(selection.selector).to eq({
            'field' => { '$gte' => 1, '$lte' => 10 },
            'key' => { '$gte' => 5, '$lte' => 7 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#elem_match' do

    let(:query_method) { :elem_match }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a criterion' do

      context 'when there are no nested complex keys' do

        let(:selection) do
          query.elem_match(users: { name: 'value' })
        end

        it 'adds the $elemMatch expression' do
          expect(selection.selector).to eq({
            'users' => { '$elemMatch' => { 'name' => 'value' } }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when there are nested complex keys' do

        let(:time) do
          Time.now
        end

        let(:selection) do
          query.elem_match(users: { time: { '$gt' => time } })
        end

        it 'adds the $elemMatch expression' do
          expect(selection.selector).to eq({
            'users' => { '$elemMatch' => { 'time' => { '$gt' => time } } }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when providing multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.elem_match(
            users: { name: 'value' },
            comments: { text: 'value' }
          )
        end

        it 'adds the $elemMatch expression' do
          expect(selection.selector).to eq({
            'users' => { '$elemMatch' => { 'name' => 'value' } },
            'comments' => { '$elemMatch' => { 'text' => 'value' } }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.elem_match(users: { name: 'value' })
               .elem_match(comments: { text: 'value' })
        end

        it 'adds the $elemMatch expression' do
          expect(selection.selector).to eq({
            'users' => { '$elemMatch' => { 'name' => 'value' } },
            'comments' => { '$elemMatch' => { 'text' => 'value' } }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when the fields are the same' do

        let(:selection) do
          query.elem_match(users: { name: 'value' })
               .elem_match(users: { state: 'new' })
        end

        it 'adds an $elemMatch expression' do
          expect(selection.selector).to eq({
            'users' => { '$elemMatch' => { 'name' => 'value' } },
            '$and' => [{ 'users' => { '$elemMatch' => { 'state' => 'new' } } }]
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#exists' do

    let(:query_method) { :exists }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a criterion' do

      context 'when provided a boolean' do

        let(:selection) do
          query.exists(users: true)
        end

        it 'adds the $exists expression' do
          expect(selection.selector).to eq({
            'users' => { '$exists' => true }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when provided a string' do

        let(:selection) do
          query.exists(users: 'yes')
        end

        it 'adds the $exists expression' do
          expect(selection.selector).to eq({
            'users' => { '$exists' => true }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when providing multiple criteria' do

      context 'when the fields differ' do

        context 'when providing boolean values' do

          let(:selection) do
            query.exists(
              users: true,
              comments: true
            )
          end

          it 'adds the $exists expression' do
            expect(selection.selector).to eq({
              'users' => { '$exists' => true },
              'comments' => { '$exists' => true }
            })
          end

          it 'returns a cloned query' do
            expect(selection).to_not equal(query)
          end
        end

        context 'when providing string values' do

          let(:selection) do
            query.exists(
              users: 'y',
              comments: 'true'
            )
          end

          it 'adds the $exists expression' do
            expect(selection.selector).to eq({
              'users' => { '$exists' => true },
              'comments' => { '$exists' => true }
            })
          end

          it 'returns a cloned query' do
            expect(selection).to_not equal(query)
          end
        end
      end
    end

    context 'when chaining multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.exists(users: true)
               .exists(comments: true)
        end

        it 'adds the $exists expression' do
          expect(selection.selector).to eq({
            'users' => { '$exists' => true },
            'comments' => { '$exists' => true }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#geo_spatial' do

    let(:query_method) { :geo_spatial }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a criterion' do

      context 'when the geometry is a point intersection' do

        let(:selection) do
          query.geo_spatial(location: { '$geoIntersects' => { '$geometry' => { type: 'Point', coordinates: [1, 10] } } })
        end

        it 'adds the $geoIntersects expression' do
          expect(selection.selector).to eq({
            'location' => {
              '$geoIntersects' => {
                '$geometry' => {
                  'type' => 'Point',
                  'coordinates' => [1, 10]
                }
              }
            }
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      context 'when the geometry is a line intersection' do

        let(:selection) do
          query.geo_spatial(location: { '$geoIntersects' => { '$geometry' => { type: 'LineString', coordinates: [[1, 10], [2, 10]] } } })
        end

        it 'adds the $geoIntersects expression' do
          expect(selection.selector).to eq({
            'location' => {
              '$geoIntersects' => {
                '$geometry' => {
                  'type' => 'LineString',
                  'coordinates' => [[1, 10], [2, 10]]
                }
              }
            }
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      context 'when the geometry is a polygon intersection' do

        let(:selection) do
          query.geo_spatial(location: { '$geoIntersects' => { '$geometry' => { type: 'Polygon', coordinates: [[1, 10], [2, 10], [1, 5]] } } })
        end

        it 'adds the $geoIntersects expression' do
          expect(selection.selector).to eq({
            'location' => {
              '$geoIntersects' => {
                '$geometry' => {
                  'type' => 'Polygon',
                  'coordinates' => [[1, 10], [2, 10], [1, 5]]
                }
              }
            }
          })
        end

        it_behaves_like 'returns a cloned query'
      end

      context 'when the geometry is within a polygon' do
        let(:selection) do
          query.geo_spatial(location: { '$geoWithin' => { '$geometry' => { type: 'Polygon', coordinates: [[1, 10], [2, 10], [1, 5]] } } })
        end

        it 'adds the $geoIntersects expression' do
          expect(selection.selector).to eq({
            'location' => {
              '$geoWithin' => {
                '$geometry' => {
                  'type' => 'Polygon',
                  'coordinates' => [[1, 10], [2, 10], [1, 5]]
                }
              }
            }
          })
        end

        context 'when used with the $box operator ($geoWithin query)' do
          let(:selection) do
            query.geo_spatial(location: { '$geoWithin' => { '$box' => [[1, 10], [2, 10]] } })
          end

          it 'adds the $geoIntersects expression' do
            expect(selection.selector).to eq({
              'location' => {
                '$geoWithin' => {
                  '$box' => [
                    [1, 10], [2, 10]
                  ]
                }
              }
            })
          end
        end

        it_behaves_like 'returns a cloned query'
      end
    end
  end

  describe '#gt' do

    let(:query_method) { :gt }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a single criterion' do

      let(:selection) do
        query.gt(field: 10)
      end

      it 'adds the $gt selector' do
        expect(selection.selector).to eq({
          'field' => { '$gt' => 10 }
        })
      end

      it 'returns a cloned query' do
        expect(selection).to_not equal(query)
      end
    end

    context 'when provided multiple criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.gt(first: 10, second: 15)
        end

        it 'adds the $gt selectors' do
          expect(selection.selector).to eq({
            'first' => { '$gt' => 10 },
            'second' => { '$gt' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining the criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.gt(first: 10).gt(second: 15)
        end

        it 'adds the $gt selectors' do
          expect(selection.selector).to eq({
            'first' => { '$gt' => 10 },
            'second' => { '$gt' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when the criterion are on the same field' do

        let(:selection) do
          query.gt(first: 10).gt(first: 15)
        end

        it 'adds a second $gt selector' do
          expect(selection.selector).to eq({
            'first' => { '$gt' => 10 },
            '$and' => [{ 'first' => { '$gt' => 15 } }]
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#gte' do

    let(:query_method) { :gte }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a single criterion' do

      let(:selection) do
        query.gte(field: 10)
      end

      it 'adds the $gte selector' do
        expect(selection.selector).to eq({
          'field' => { '$gte' => 10 }
        })
      end

      it 'returns a cloned query' do
        expect(selection).to_not equal(query)
      end
    end

    context 'when provided multiple criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.gte(first: 10, second: 15)
        end

        it 'adds the $gte selectors' do
          expect(selection.selector).to eq({
            'first' => { '$gte' => 10 },
            'second' => { '$gte' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining the criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.gte(first: 10).gte(second: 15)
        end

        it 'adds the $gte selectors' do
          expect(selection.selector).to eq({
            'first' => { '$gte' => 10 },
            'second' => { '$gte' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when the criterion are on the same field' do

        let(:selection) do
          query.gte(first: 10).gte(first: 15)
        end

        it 'adds a second $gte selector' do
          expect(selection.selector).to eq({
            'first' => { '$gte' => 10 },
            '$and' => [{ 'first' => { '$gte' => 15 } }]
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#any_in' do
    let(:query_method) { :any_in }
    let(:operator) { '$in' }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a single criterion' do

      context 'when providing an array' do
        let(:selection) do
          query.any_in(field: [1, 2])
        end

        it 'adds the $in selector' do
          expect(selection.selector).to eq({
            'field' => { '$in' => [1, 2] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when providing a single value' do

        let(:selection) do
          query.any_in(field: 1)
        end

        it 'adds the $in selector with wrapped value' do
          expect(selection.selector).to eq({
            'field' => { '$in' => [1] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when provided multiple criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.any_in(first: [1, 2], second: 3..4)
        end

        it 'adds the $in selectors' do
          expect(selection.selector).to eq({
            'first' => { '$in' => [1, 2] },
            'second' => { '$in' => [3, 4] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining the criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.any_in(first: [1, 2]).any_in(second: [3, 4])
        end

        it 'adds the $in selectors' do
          expect(selection.selector).to eq({
            'first' => { '$in' => [1, 2] },
            'second' => { '$in' => [3, 4] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when the criterion are on the same field' do
        it_behaves_like 'ands the arguments'
        # TODO: it_behaves_like 'intersects the arguments'
      end
    end
  end

  describe '#lt' do

    let(:query_method) { :lt }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a single criterion' do

      let(:selection) do
        query.lt(field: 10)
      end

      it 'adds the $lt selector' do
        expect(selection.selector).to eq({
          'field' => { '$lt' => 10 }
        })
      end

      it 'returns a cloned query' do
        expect(selection).to_not equal(query)
      end
    end

    context 'when provided multiple criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.lt(first: 10, second: 15)
        end

        it 'adds the $lt selectors' do
          expect(selection.selector).to eq({
            'first' => { '$lt' => 10 },
            'second' => { '$lt' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining the criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.lt(first: 10).lt(second: 15)
        end

        it 'adds the $lt selectors' do
          expect(selection.selector).to eq({
            'first' => { '$lt' => 10 },
            'second' => { '$lt' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when the criterion are on the same field' do

        let(:selection) do
          query.lt(first: 10).lt(first: 15)
        end

        it 'adds a second $lt selector' do
          expect(selection.selector).to eq({
            'first' => { '$lt' => 10 },
            '$and' => [{ 'first' => { '$lt' => 15 } }]
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#lte' do

    let(:query_method) { :lte }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a single criterion' do

      let(:selection) do
        query.lte(field: 10)
      end

      it 'adds the $lte selector' do
        expect(selection.selector).to eq({
          'field' => { '$lte' => 10 }
        })
      end

      it 'returns a cloned query' do
        expect(selection).to_not equal(query)
      end
    end

    context 'when provided multiple criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.lte(first: 10, second: 15)
        end

        it 'adds the $lte selectors' do
          expect(selection.selector).to eq({
            'first' => { '$lte' => 10 },
            'second' => { '$lte' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining the criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.lte(first: 10).lte(second: 15)
        end

        it 'adds the $lte selectors' do
          expect(selection.selector).to eq({
            'first' => { '$lte' => 10 },
            'second' => { '$lte' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when the criterion are on the same field' do

        let(:selection) do
          query.lte(first: 10).lte(first: 15)
        end

        it 'adds a second $lte selector' do
          expect(selection.selector).to eq({
            'first' => { '$lte' => 10 },
            '$and' => [{ 'first' => { '$lte' => 15 } }]
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#max_distance' do

    let(:query_method) { :max_distance }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a criterion' do

      context 'when a $near criterion exists on the same field' do

        let(:selection) do
          query.near(location: [1, 1]).max_distance(location: 50)
        end

        it 'adds the $maxDistance expression' do
          expect(selection.selector).to eq({
            'location' => { '$near' => [1, 1], '$maxDistance' => 50 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#mod' do

    let(:query_method) { :mod }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a criterion' do

      let(:selection) do
        query.mod(value: [10, 1])
      end

      it 'adds the $mod expression' do
        expect(selection.selector).to eq({
          'value' => { '$mod' => [10, 1] }
        })
      end

      it 'returns a cloned query' do
        expect(selection).to_not equal(query)
      end
    end

    context 'when providing multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.mod(value: [10, 1], comments: [10, 1])
        end

        it 'adds the $mod expression' do
          expect(selection.selector).to eq({
            'value' => { '$mod' => [10, 1] },
            'comments' => { '$mod' => [10, 1] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.mod(value: [10, 1])
               .mod(result: [10, 1])
        end

        it 'adds the $mod expression' do
          expect(selection.selector).to eq({
            'value' => { '$mod' => [10, 1] },
            'result' => { '$mod' => [10, 1] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#ne' do

    let(:query_method) { :ne }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a criterion' do

      let(:selection) do
        query.ne(value: 10)
      end

      it 'adds the $ne expression' do
        expect(selection.selector).to eq({
          'value' => { '$ne' => 10 }
        })
      end

      it 'returns a cloned query' do
        expect(selection).to_not equal(query)
      end
    end

    context 'when providing multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.ne(
            value: 10,
            comments: 10
          )
        end

        it 'adds the $ne expression' do
          expect(selection.selector).to eq({
            'value' => { '$ne' => 10 },
            'comments' => { '$ne' => 10 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.ne(value: 10)
               .ne(result: 10)
        end

        it 'adds the $ne expression' do
          expect(selection.selector).to eq({
            'value' => { '$ne' => 10 },
            'result' => { '$ne' => 10 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#near' do

    let(:query_method) { :near }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a criterion' do

      let(:selection) do
        query.near(location: [20, 21])
      end

      it 'adds the $near expression' do
        expect(selection.selector).to eq({
          'location' => { '$near' => [20, 21] }
        })
      end

      it 'returns a cloned query' do
        expect(selection).to_not equal(query)
      end
    end

    context 'when providing multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.near(location: [20, 21], comments: [20, 21])
        end

        it 'adds the $near expression' do
          expect(selection.selector).to eq({
            'location' => { '$near' => [20, 21] },
            'comments' => { '$near' => [20, 21] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.near(location: [20, 21])
               .near(comments: [20, 21])
        end

        it 'adds the $near expression' do
          expect(selection.selector).to eq({
            'location' => { '$near' => [20, 21] },
            'comments' => { '$near' => [20, 21] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#near_sphere' do

    let(:query_method) { :near_sphere }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a criterion' do

      let(:selection) do
        query.near_sphere(location: [20, 21])
      end

      it 'adds the $nearSphere expression' do
        expect(selection.selector).to eq({
          'location' => { '$nearSphere' => [20, 21] }
        })
      end

      it 'returns a cloned query' do
        expect(selection).to_not equal(query)
      end
    end

    context 'when providing multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.near_sphere(location: [20, 21], comments: [20, 21])
        end

        it 'adds the $nearSphere expression' do
          expect(selection.selector).to eq({
            'location' => { '$nearSphere' => [20, 21] },
            'comments' => { '$nearSphere' => [20, 21] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining multiple criteria' do

      context 'when the fields differ' do

        let(:selection) do
          query.near_sphere(location: [20, 21])
               .near_sphere(comments: [20, 21])
        end

        it 'adds the $nearSphere expression' do
          expect(selection.selector).to eq({
            'location' => { '$nearSphere' => [20, 21] },
            'comments' => { '$nearSphere' => [20, 21] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#nin' do

    let(:query_method) { :nin }
    let(:operator) { '$nin' }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a single criterion' do

      context 'when providing an array' do

        let(:selection) do
          query.nin(field: [1, 2])
        end

        it 'adds the $nin selector' do
          expect(selection.selector).to eq({
            'field' => { '$nin' => [1, 2] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when providing a single value' do

        let(:selection) do
          query.nin(field: 1)
        end

        it 'adds the $nin selector with wrapped value' do
          expect(selection.selector).to eq({
            'field' => { '$nin' => [1] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when provided multiple criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.nin(first: [1, 2], second: [3, 4])
        end

        it 'adds the $nin selectors' do
          expect(selection.selector).to eq({
            'first' => { '$nin' => [1, 2] },
            'second' => { '$nin' => [3, 4] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining the criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.nin(first: [1, 2]).nin(second: [3, 4])
        end

        it 'adds the $nin selectors' do
          expect(selection.selector).to eq({
            'first' => { '$nin' => [1, 2] },
            'second' => { '$nin' => [3, 4] }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when the criterion are on the same field' do
        it_behaves_like 'ands the arguments'
        # TODO: it_behaves_like 'unions the arguments'
      end
    end
  end

  describe '#size_of' do
    let(:query_method) { :size_of }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a single criterion' do

      context 'when provided an integer' do

        let(:selection) do
          query.size_of(field: 10)
        end

        it 'adds the $size selector' do
          expect(selection.selector).to eq({
            'field' => { '$size' => 10 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when provided a string' do

        let(:selection) do
          query.size_of(field: '10')
        end

        it 'adds the $size selector with an integer' do
          expect(selection.selector).to eq({
            'field' => { '$size' => 10 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when provided multiple criterion' do

      context 'when the criterion are for different fields' do

        context 'when provided integers' do

          let(:selection) do
            query.size_of(first: 10, second: 15)
          end

          it 'adds the $size selectors' do
            expect(selection.selector).to eq({
              'first' => { '$size' => 10 },
              'second' => { '$size' => 15 }
            })
          end

          it 'returns a cloned query' do
            expect(selection).to_not equal(query)
          end
        end

        context 'when provided strings' do

          let(:selection) do
            query.size_of(first: '10', second: '15')
          end

          it 'adds the $size selectors' do
            expect(selection.selector).to eq({
              'first' => { '$size' => 10 },
              'second' => { '$size' => 15 }
            })
          end

          it 'returns a cloned query' do
            expect(selection).to_not equal(query)
          end
        end
      end
    end

    context 'when chaining the criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.size_of(first: 10).size_of(second: 15)
        end

        it 'adds the $size selectors' do
          expect(selection.selector).to eq({
            'first' => { '$size' => 10 },
            'second' => { '$size' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when the criterion are on the same field' do

        let(:selection) do
          query.size_of(first: 10).size_of(first: 15)
        end

        it 'overwrites the first $size selector' do
          expect(selection.selector).to eq({
            'first' => { '$size' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#type_of' do

    let(:query_method) { :type_of }

    it_behaves_like 'requires an argument'
    it_behaves_like 'requires a non-nil argument'

    context 'when provided a single criterion' do

      context 'when provided an integer' do

        let(:selection) do
          query.type_of(field: 10)
        end

        it 'adds the $type selector' do
          expect(selection.selector).to eq({
            'field' => { '$type' => 10 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when provided a string' do

        let(:selection) do
          query.type_of(field: '10')
        end

        it 'adds the $type selector' do
          expect(selection.selector).to eq({
            'field' => { '$type' => 10 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when provided multiple criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.type_of(first: 10, second: 15)
        end

        it 'adds the $type selectors' do
          expect(selection.selector).to eq({
            'first' => { '$type' => 10 },
            'second' => { '$type' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end

    context 'when chaining the criterion' do

      context 'when the criterion are for different fields' do

        let(:selection) do
          query.type_of(first: 10).type_of(second: 15)
        end

        it 'adds the $type selectors' do
          expect(selection.selector).to eq({
            'first' => { '$type' => 10 },
            'second' => { '$type' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end

      context 'when the criterion are on the same field' do

        let(:selection) do
          query.type_of(first: 10).type_of(first: 15)
        end

        it 'overwrites the first $type selector' do
          expect(selection.selector).to eq({
            'first' => { '$type' => 15 }
          })
        end

        it 'returns a cloned query' do
          expect(selection).to_not equal(query)
        end
      end
    end
  end

  describe '#text_search' do

    context 'when providing a search string' do

      let(:selection) do
        query.text_search('testing')
      end

      it 'constructs a text search document' do
        expect(selection.selector).to eq({ '$text' => { '$search' => 'testing' } })
      end

      it 'returns the cloned selectable' do
        expect(selection).to be_a(described_class)
      end

      context 'when providing text search options' do

        let(:selection) do
          query.text_search('essais', { :$language => 'fr' })
        end

        it 'constructs a text search document' do
          expect(selection.selector['$text']['$search']).to eq('essais')
        end

        it 'add the options to the text search document' do
          expect(selection.selector['$text'][:$language]).to eq('fr')
        end

        it_behaves_like 'returns a cloned query'
      end
    end

    context 'when given more than once' do
      let(:selection) do
        query.text_search('one').text_search('two')
      end

      # MongoDB server can only handle one text expression at a time,
      # per https://www.mongodb.com/docs/manual/reference/operator/query/text/.
      # Nonetheless we test that the query is built correctly when
      # a user supplies more than one text condition.
      it 'merges conditions' do
        expect(ActiveDocument.logger).to receive(:warn)
        expect(selection.selector).to eq(
          '$and' => [
            { '$text' => { '$search' => 'one' } }
          ],
          '$text' => { '$search' => 'two' }
        )
      end
    end
  end

  context 'when using multiple operators on the same field' do

    context 'when different operators are specified' do
      let(:selection) do
        query.gt(field: 5).lt(field: 10).ne(field: 7)
      end

      it 'merges the operators on the same field' do
        expect(selection.selector).to eq(
          'field' => { '$gt' => 5, '$lt' => 10, '$ne' => 7 }
        )
      end
    end

    context 'when the same operator is specified' do
      let(:selection) do
        query.where(field: 5).where(field: 10)
      end

      it 'combines conditions' do
        # TODO: this should be the below:
        # expect(selection.selector).to eq('$and' => [{ 'field' => 5 }, { 'field' => 10 }])
        expect(selection.selector).to eq('field' => 5, '$and' => [{ 'field' => 10 }])
      end
    end

    context 'when using complex keys with different operators' do
      let(:selection) do
        query.where(field: { '$gt' => 5, '$lt' => 10, '$ne' => 7 })
      end

      it 'merges the strategies on the same field' do
        expect(selection.selector).to eq(
          'field' => { '$gt' => 5, '$lt' => 10, '$ne' => 7 }
        )
      end
    end

    context 'when using complex keys with different and same operators' do
      let(:selection) do
        query.where(field: { '$gt' => 5, '$lt' => 10, '$ne' => 7 })
             .where(field: { '$gt' => 6 })
             .where(field: 42)
      end

      it 'merges the strategies on the same field' do
        # TODO: this should be the below:
        # expect(selection.selector).to eq(
        #   '$and' => [
        #     { 'field' => { '$gt' => 5, '$lt' => 10, '$ne' => 7 } },
        #     { 'field' => { '$gt' => 6 } },
        #     { 'field' => 42 }
        #   ]
        # )
        expect(selection.selector).to eq(
          'field' => { '$gt' => 5, '$lt' => 10, '$ne' => 7 },
          '$and' => [{ 'field' => { '$gt' => 6 } }, { 'field' => 42 }]
        )
      end
    end
  end

  describe 'chained operators' do
    %i[eq elem_match gt gte lt lte mod ne near near_sphere].each do |meth|

      context "when chaining the #{meth} method when using the same field" do
        let(:op) do
          {
            eq: '$eq',
            elem_match: '$elemMatch',
            gt: '$gt',
            gte: '$gte',
            lt: '$lt',
            lte: '$lte',
            mod: '$mod',
            ne: '$ne',
            near: '$near',
            near_sphere: '$nearSphere'
          }[meth]
        end

        let(:criteria) do
          Band.send(meth, { views: 1 }).send(meth, { views: 2 })
        end

        it 'is and-ed with the previous operators' do
          expect(criteria.selector).to eq({
            'views' => { op => 1 },
            '$and' => [{ 'views' => { op => 2 } }]
          })
        end
      end
    end
  end
end
