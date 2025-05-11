# frozen_string_literal: true

require 'spec_helper'
begin
  require 'active_job'
  require 'active_document/railties/bson_object_id_serializer'

  describe 'ActiveJob Serialization' do
    skip unless defined?(ActiveJob)

    class TestBsonObjectIdSerializerJob < ApplicationJob
      def perform(*args)
        args
      end
    end

    let(:band) do
      Band.create!
    end

    before do
      ActiveJob::Serializers.add_serializers(
        [ActiveDocument::Railties::ActiveJobSerializers::BsonObjectIdSerializer]
      )
    end

    it 'serializes and deserializes BSON::ObjectId' do
      expect do
        TestBsonObjectIdSerializerJob.perform_later(band.id)
      end.to_not raise_error
    end
  end
rescue LoadError
  RSpec.context.skip 'This test requires active_job'
end
