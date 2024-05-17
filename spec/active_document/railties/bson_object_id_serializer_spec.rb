# frozen_string_literal: true

require 'spec_helper'
require 'active_job'
require 'active_document/railties/bson_object_id_serializer'

describe 'ActiveDocument::Railties::ActiveJobSerializers::BsonObjectIdSerializer' do

  let(:serializer) { ActiveDocument::Railties::ActiveJobSerializers::BsonObjectIdSerializer.instance }
  let(:object_id) { BSON::ObjectId.new }

  describe '#serialize' do
    it 'serializes BSON::ObjectId' do
      expect(serializer.serialize(object_id)).to be_a(String)
    end
  end

  describe '#deserialize' do
    it 'deserializes BSON::ObjectId' do
      expect(serializer.deserialize(serializer.serialize(object_id))).to eq(object_id)
    end
  end
end
