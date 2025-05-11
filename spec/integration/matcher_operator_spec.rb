# frozen_string_literal: true

require 'spec_helper'

def mop_error?(spec, kind)
  raise ArgumentError.new("Bogus kind: #{kind}") unless %w[matcher driver dsl].include?(kind)

  spec['error'] == true || spec['error'] == kind ||
    (spec['error'].is_a?(Array) && spec['error'].include?(kind))
end

describe 'Matcher operators' do
  config_override :map_big_decimal_to_decimal128, true

  Dir[File.join(File.dirname(__FILE__), 'matcher_operator_data', '*.yml')].each do |path|
    context File.basename(path) do
      permitted_classes = [BigDecimal,
                           Date,
                           Time,
                           Range,
                           Regexp,
                           Symbol,
                           BSON::Binary,
                           BSON::Code,
                           BSON::CodeWithScope,
                           BSON::DbPointer,
                           BSON::Decimal128,
                           BSON::Int32,
                           BSON::Int64,
                           BSON::MaxKey,
                           BSON::MinKey,
                           BSON::ObjectId,
                           BSON::Regexp::Raw,
                           BSON::Symbol::Raw,
                           BSON::Timestamp,
                           BSON::Undefined]

      specs = YAML.safe_load_file(path, permitted_classes: permitted_classes, aliases: true)

      specs.each do |spec|
        context spec['name'] do

          if spec['pending']
            before do
              # Cannot use `pending` here because some of the queries may work
              # as specified (e.g. when ActiveDocument and server behavior differ).
              skip spec['pending'].to_s
            end
          end

          min_server_version spec['min_server_version'].to_s if spec['min_server_version']

          let(:query) { spec.fetch('query') }
          let(:result) { spec.fetch('matches') }

          context 'embedded matching' do
            let(:document) { Mop.new(spec.fetch('document')) }

            if mop_error?(spec, 'matcher')
              it 'produces an error' do
                expect do
                  document._matches?(query)
                end.to raise_error(ActiveDocument::Errors::InvalidQuery)
              end
            else
              it 'produces the correct result' do
                expect(document._matches?(query)).to be result
              end
            end
          end

          context 'server query' do
            let!(:document) { Mop.create!(spec.fetch('document')) }

            context 'via driver' do
              if mop_error?(spec, 'driver')
                it 'produces an error' do
                  Mop.collection.find(query).any?
                rescue Mongo::Error::OperationFailure
                rescue Mongo::Error::InvalidDocument
                rescue BSON::Error::UnserializableClass
                else
                  raise 'Expected an exception to be raised'
                end
              else
                it 'produces the correct result' do
                  expect(Mop.collection.find(query).any?).to be result
                end
              end
            end

            context 'via ActiveDocument DSL' do
              if mop_error?(spec, 'dsl')
                it 'produces an error' do
                  Mop.where(query).any?
                rescue Mongo::Error::OperationFailure
                rescue BSON::Error::UnserializableClass
                rescue ActiveDocument::Errors::InvalidQuery
                rescue ActiveDocument::Errors::CriteriaArgumentRequired
                else
                  raise 'Expected the query to raise an error'
                end
              else
                it 'produces the correct result' do
                  expect(Mop.where(query).any?).to be result
                end
              end
            end
          end
        end
      end
    end
  end
end
