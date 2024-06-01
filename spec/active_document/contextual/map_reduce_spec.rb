# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Contextual::MapReduce do

  let(:map) do
    <<~JAVASCRIPT
      function() {
        emit(this.name, { likes: this.likes });
      }
    JAVASCRIPT
  end

  let(:reduce) do
    <<~JAVASCRIPT
      function(key, values) {
        var result = { likes: 0 };
        values.forEach(function(value) {
          result.likes += value.likes;
        });
        return result;
      }
    JAVASCRIPT
  end

  let!(:depeche_mode) do
    Band.create!(name: 'Depeche Mode', likes: 200)
  end

  let!(:tool) do
    Band.create!(name: 'Tool', likes: 100)
  end

  let!(:collection) do
    Band.collection
  end

  let(:criteria) do
    Band.all
  end

  let(:map_reduce) do
    described_class.new(collection, criteria, map, reduce)
  end

  describe '#command' do

    let(:base_command) do
      {
        mapreduce: 'bands',
        map: map,
        reduce: reduce,
        query: {}
      }
    end

    context 'with sort' do

      let(:criteria) do
        Band.order_by(name: -1)
      end

      it 'includes a sort option in the map reduce command' do
        expect(map_reduce.command[:sort]).to eq('name' => -1)
      end
    end

    context 'with limit' do

      let(:criteria) do
        Band.limit(10)
      end

      it 'returns the db command with a limit option' do
        expect(map_reduce.command[:limit]).to eq(10)
      end
    end
  end

  describe '#each' do

    context 'when the map/reduce is inline' do

      let(:results) do
        map_reduce.out(inline: 1)
      end

      it 'iterates over the results' do
        ordered_results = results.entries.sort_by { |doc| doc['_id'] }
        expected = [
          { '_id' => 'Depeche Mode', 'value' => { 'likes' => 200 } },
          { '_id' => 'Tool', 'value' => { 'likes' => 100 } }
        ]
        expect(ordered_results.entries).to eq(expected)
      end
    end

    context 'when the map/reduce is a collection' do

      let(:results) do
        map_reduce.out(replace: 'mr-output')
      end

      let(:expected_results) do
        [
          { '_id' => 'Depeche Mode', 'value' => { 'likes' => 200 } },
          { '_id' => 'Tool', 'value' => { 'likes' => 100 } }
        ]
      end

      it 'iterates over the results' do
        ordered_results = results.entries.sort_by { |doc| doc['_id'] }
        expect(ordered_results).to eq(expected_results)
      end

      it 'outputs to the collection' do
        expect(results.entries).to eq(map_reduce.criteria.view.database['mr-output'].find.to_a)
      end
    end

    context 'when no output is provided' do

      context 'when the results are iterated' do

        it 'raises an error' do
          expect do
            map_reduce.entries
          end.to raise_error(ActiveDocument::Errors::NoMapReduceOutput)
        end
      end
    end

    context 'when no results are returned' do

      let(:results) do
        map_reduce.out(replace: 'mr-output-two')
      end

      before do
        Band.delete_all
      end

      it 'does not raise an error' do
        expect(results.entries).to be_empty
      end
    end

    context 'when there is a collation on the criteria' do

      let(:map) do
        <<~JAVASCRIPT
          function() {
            emit(this.name, 1);
          }
        JAVASCRIPT
      end

      let(:reduce) do
        <<~JAVASCRIPT
          function(key, values) {
            return Array.sum(values);
          }
        JAVASCRIPT
      end

      let(:criteria) do
        Band.where(name: 'DEPECHE MODE').collation(locale: 'en_US', strength: 2)
      end

      it 'applies the collation' do
        expect(map_reduce.out(inline: 1).count).to eq(1)
      end
    end
  end

  describe '#empty?' do

    context 'when the map/reduce has results' do

      let(:results) do
        map_reduce.out(inline: 1)
      end

      it 'returns false' do
        expect(results).to_not be_empty
      end
    end

    context 'when the map/reduce has no results' do

      let(:criteria) do
        Band.where(name: 'Pet Shop Boys')
      end

      let(:results) do
        map_reduce.out(inline: 1)
      end

      it 'returns true' do
        expect(results).to be_empty
      end
    end
  end

  describe '#finalize' do

    let(:finalized) do
      map_reduce.finalize('testing')
    end

    it 'sets the finalize command' do
      expect(finalized.command[:finalize]).to eq('testing')
    end
  end

  describe '#js_mode' do

    let(:results) do
      map_reduce.out(inline: 1).js_mode
    end

    it 'adds the jsMode flag to the command' do
      expect(results.command[:jsMode]).to be true
    end
  end

  describe '#out' do

    context 'when providing inline' do

      let(:out) do
        map_reduce.out(inline: 1)
      end

      it 'sets the out command' do
        expect(out.command[:out][:inline]).to eq(1)
      end
    end

    context 'when not providing inline' do

      context 'when the value is a symbol' do

        let(:out) do
          map_reduce.out(replace: :test)
        end

        it 'sets the out command value to a string' do
          expect(out.command[:out][:replace]).to eq('test')
        end
      end
    end
  end

  describe '#raw' do

    let(:client) do
      collection.database.client
    end

    context 'when not specifying an out' do

      it 'raises a NoMapReduceOutput error' do
        expect do
          map_reduce.raw
        end.to raise_error(ActiveDocument::Errors::NoMapReduceOutput)
      end
    end

    context 'when providing replace' do

      let(:replace_map_reduce) do
        map_reduce.out(replace: 'output-collection')
      end
    end
  end

  describe '#scope' do

    let(:finalize) do
      <<~JAVASCRIPT
        function(key, value) {
          value.global = test;
          return value;
        }
      JAVASCRIPT
    end

    let(:results) do
      map_reduce.out(inline: 1).scope(test: 5).finalize(finalize)
    end

    it 'adds the variables to the global js scope' do
      expect(results.first['value']['global']).to eq(5)
    end
  end

  describe '#execute' do
    let(:execution_results) do
      map_reduce.out(inline: 1).execute
    end

    it 'returns a hash' do
      expect(execution_results).to be_a Hash
    end
  end

  describe '#inspect' do

    let(:criteria) do
      Band.where(name: 'Depeche Mode')
    end

    let(:out) do
      { inline: 1 }
    end

    let(:map_reduce) do
      described_class.new(collection, criteria, map, reduce).out(out)
    end

    let(:inspection) do
      map_reduce.inspect
    end

    it 'returns a string' do
      expect(inspection).to be_a String
    end

    it 'includes the criteria selector' do
      expect(inspection).to include('selector:')
    end

    it 'includes the class' do
      expect(inspection).to include('class:')
    end

    it 'includes the map function' do
      expect(inspection).to include('map:')
    end

    it 'includes the reduce function' do
      expect(inspection).to include('reduce:')
    end

    it 'includes the finalize function' do
      expect(inspection).to include('finalize:')
    end

    it 'includes the out option' do
      expect(inspection).to include('out:')
    end
  end
end
