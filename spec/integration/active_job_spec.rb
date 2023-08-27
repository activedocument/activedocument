# frozen_string_literal: true

require 'spec_helper'
require 'active_job'
require 'mongoid/railties/bson_object_id_serializer'

describe 'ActiveJob Serialization' do
  skip unless defined?(ActiveJob)

  unless defined?(ApplicationJob)
    class ApplicationJob < ActiveJob::Base
    end
  end

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
      [Mongoid::Railties::ActiveJobSerializers::BsonObjectIdSerializer]
    )
  end

  it 'serializes and deserializes BSON::ObjectId' do
    expect do
      TestBsonObjectIdSerializerJob.perform_later(band.id)
    end.to_not raise_error
  end
end
