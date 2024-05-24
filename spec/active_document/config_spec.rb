# frozen_string_literal: true

require 'spec_helper'
require 'support/feature_sandbox'

describe ActiveDocument::Config do

  after do
    ActiveDocument.configure do |config|
      config.load_configuration(CONFIG)
    end
  end

  describe '#configured?' do

    after do
      described_class.connect_to(database_id, read: :primary)
    end

    context 'when a default client config exists' do

      context 'when a default database is configured' do

        let(:config) do
          {
            default: {
              database: database_id,
              hosts: ['127.0.0.1:27017']
            }
          }
        end

        before do
          described_class.send(:clients=, config)
        end

        it 'returns true' do
          expect(described_class).to be_configured
        end
      end
    end

    context 'when no default client config exists' do

      before do
        described_class.clients.clear
      end

      it 'returns false' do
        expect(described_class).to_not be_configured
      end
    end
  end

  describe '#destructive_fields' do

    ActiveDocument::Composable.prohibited_methods.each do |method|

      it "contains #{method}" do
        expect(described_class.destructive_fields).to include(method)
      end
    end
  end

  context 'when the log level is not set in the configuration' do

    before do
      ActiveDocument.configure do |config|
        config.load_configuration(CONFIG)
      end
    end

    it 'sets the ActiveDocument logger level to the default' do
      expect(ActiveDocument.logger.level).to eq(Logger::INFO)
    end

    it 'sets the Mongo driver logger level to the default' do
      expect(Mongo::Logger.logger.level).to eq(Logger::INFO)
    end
  end

  context 'when the belongs_to_required_by_default option is not set in the config' do

    before do
      described_class.reset
      ActiveDocument.configure do |config|
        config.load_configuration(clients: CONFIG[:clients])
      end
    end

    it 'sets the ActiveDocument.belongs_to_required_by_default value to true' do
      expect(ActiveDocument.belongs_to_required_by_default).to be(true)
    end
  end

  context 'when the belongs_to_required_by_default option is set in the config' do

    before do
      ActiveDocument.configure do |config|
        config.load_configuration(conf)
      end
    end

    context 'when the value is set to true' do

      let(:conf) do
        CONFIG.merge(options: { belongs_to_required_by_default: true })
      end

      it 'sets the ActiveDocument.belongs_to_required_by_default value to true' do
        expect(ActiveDocument.belongs_to_required_by_default).to be(true)
      end
    end

    context 'when the value is set to false' do

      let(:conf) do
        CONFIG.merge(options: { belongs_to_required_by_default: false })
      end

      before do
        described_class.reset
        ActiveDocument.configure do |config|
          config.load_configuration(conf)
        end
      end

      it 'sets the ActiveDocument.belongs_to_required_by_default value to false' do
        expect(ActiveDocument.belongs_to_required_by_default).to be(false)
      end
    end
  end

  context 'when the app_name is set in the config' do

    let(:conf) do
      CONFIG.merge(options: { app_name: 'admin-reporting' })
    end

    before do
      ActiveDocument.configure do |config|
        config.load_configuration(conf)
      end
    end

    it 'sets the ActiveDocument.app_name to the provided value' do
      expect(ActiveDocument.app_name).to eq('admin-reporting')
    end
  end

  context 'when the app_name is not set in the config' do

    before do
      described_class.reset
      ActiveDocument.configure do |config|
        config.load_configuration(CONFIG)
      end
    end

    it 'does not set the ActiveDocument.app_name option' do
      expect(ActiveDocument.app_name).to be_nil
    end
  end

  context 'when discriminator_key override' do
    context 'is not set in the config' do
      it 'has the value _type by default' do
        described_class.reset
        configuration = CONFIG.merge(options: {})

        ActiveDocument.configure { |config| config.load_configuration(configuration) }

        expect(described_class.discriminator_key).to eq('_type')
      end
    end

    context 'is set in the config' do
      it 'sets the value' do
        described_class.reset
        configuration = CONFIG.merge(options: { discriminator_key: 'test' })

        ActiveDocument.configure { |config| config.load_configuration(configuration) }

        expect(described_class.discriminator_key).to eq('test')
      end

      it 'is set globally' do
        expect(ActiveDocument.discriminator_key).to eq('test')
      end
    end
  end

  context 'async_query_executor option' do
    let(:option) { :async_query_executor }

    before do
      described_class.reset
      ActiveDocument.configure do |config|
        config.load_configuration(conf)
      end
    end

    context 'when it is not set in the config' do

      let(:conf) { CONFIG }

      it 'is set to its default' do
        expect(ActiveDocument.send(option)).to eq(:immediate)
      end
    end

    context 'when the value is :immediate' do

      let(:conf) do
        CONFIG.merge(options: { option => :immediate })
      end

      it 'is set to false' do
        expect(ActiveDocument.send(option)).to be(:immediate)
      end
    end

    context 'when the value is :global_thread_pool' do

      let(:conf) do
        CONFIG.merge(options: { option => :global_thread_pool })
      end

      it 'is set to false' do
        expect(ActiveDocument.send(option)).to be(:global_thread_pool)
      end
    end
  end

  context 'global_executor_concurrency option' do
    let(:option) { :global_executor_concurrency }

    before do
      described_class.reset
      ActiveDocument.configure do |config|
        config.load_configuration(conf)
      end
    end

    context 'when it is not set in the config' do

      let(:conf) { CONFIG }

      it 'is set to its default' do
        expect(ActiveDocument.send(option)).to be_nil
      end
    end

    context 'when the value is set to a number' do

      let(:conf) do
        CONFIG.merge(options: { option => 5 })
      end

      it 'is set to the number' do
        expect(ActiveDocument.send(option)).to be(5)
      end
    end
  end

  shared_examples 'a config option' do

    before do
      described_class.reset
      ActiveDocument.configure do |config|
        config.load_configuration(conf)
      end
    end

    context 'when the value is false' do

      let(:conf) do
        CONFIG.merge(options: { option => false })
      end

      it 'is set to false' do
        expect(ActiveDocument.send(option)).to be(false)
      end
    end

    context 'when the value is true' do

      let(:conf) do
        CONFIG.merge(options: { option => true })
      end

      it 'is set to true' do
        expect(ActiveDocument.send(option)).to be(true)
      end
    end

    context 'when it is not set in the config' do

      let(:conf) { CONFIG }

      it 'is set to its default' do
        expect(ActiveDocument.send(option)).to eq(default)
      end
    end
  end

  context 'when setting the map_big_decimal_to_decimal128 option in the config' do
    let(:option) { :map_big_decimal_to_decimal128 }
    let(:default) { true }

    it_behaves_like 'a config option'
  end

  context 'when setting the allow_bson5_decimal128 option in the config' do
    min_bson_version '5.0'

    let(:option) { :allow_bson5_decimal128 }
    let(:default) { false }

    it_behaves_like 'a config option'
  end

  context 'when setting the legacy_readonly option in the config' do
    let(:option) { :legacy_readonly }
    let(:default) { false }

    it_behaves_like 'a config option'
  end

  context 'when setting the legacy_persistence_context_behavior option in the config' do
    let(:option) { :legacy_persistence_context_behavior }
    let(:default) { false }

    it_behaves_like 'a config option'
  end

  describe '#load!' do

    let(:file) do
      File.join(File.dirname(__FILE__), '..', 'config', 'active_document.yml')
    end

    context 'when existing clients exist in the configuration' do

      let(:client) do
        Mongo::Client.new(['127.0.0.1:27017'])
      end

      before do
        ActiveDocument::Clients.clients[:test] = client
        described_class.load!(file, :test)
      end

      after do
        client.close
      end

      it 'clears the previous clients' do
        expect(ActiveDocument::Clients.clients[:test]).to be_nil
      end
    end

    context 'when the log level is set in the configuration' do

      before do
        described_class.load!(file, :test)
      end

      it 'sets the ActiveDocument logger level' do
        expect(ActiveDocument.logger.level).to eq(Logger::WARN)
      end

      it 'sets the Mongo driver logger level' do
        expect(Mongo::Logger.logger.level).to eq(Logger::WARN)
      end

      context 'when in a Rails environment' do

        around do |example|
          FeatureSandbox.quarantine do
            require 'support/rails_mock'
            ActiveDocument.logger = Rails.logger
            described_class.load!(file, :test)
            example.run
          end
        end

        it 'keeps the ActiveDocument logger level the same as the Rails logger' do
          expect(ActiveDocument.logger.level).to eq(Rails.logger.level)
          expect(ActiveDocument.logger.level).to_not eq(described_class.log_level)
        end

        it "sets the Mongo driver logger level to ActiveDocument's logger level" do
          expect(Mongo::Logger.logger.level).to eq(ActiveDocument.logger.level)
        end
      end
    end

    context 'when provided an environment' do

      before do
        described_class.load!(file, :test)
      end

      after do
        described_class.reset
      end

      it 'sets the include root in json option' do
        expect(described_class.include_root_in_json).to be false
      end

      it 'sets the include type with serialization option' do
        expect(described_class.include_type_for_serialization).to be false
      end

      it 'sets the scope overwrite option' do
        expect(described_class.scope_overwrite_exception).to be false
      end

      it 'sets the preload models option' do
        expect(described_class.preload_models).to be false
      end

      it 'sets the raise not found error option' do
        expect(described_class.raise_not_found_error).to be true
      end

      it 'sets the use utc option' do
        expect(described_class.use_utc).to be false
      end

      it 'sets the join_contexts default option' do
        expect(described_class.join_contexts).to be false
      end
    end

    context 'when provided an environment with driver options' do

      before do
        described_class.load!(file, :test)
      end

      after do
        described_class.reset
      end

      it 'sets the Mongo.broken_view_options option' do
        expect(Mongo.broken_view_options).to be(false)
      end

      it 'does not override the unset Mongo.validate_update_replace option' do
        expect(Mongo.validate_update_replace).to be(false)
      end
    end

    context 'when provided an environment with a nil driver option' do

      before do
        described_class.load!(file, :test_nil)
      end

      after do
        described_class.reset
      end

      it 'sets the Mongo.broken_view_options option to nil' do
        expect(Mongo.broken_view_options).to be_nil
      end
    end

    context 'when the rack environment is set' do

      before do
        ENV['RACK_ENV'] = 'test'
      end

      after do
        ENV['RACK_ENV'] = nil
        described_class.reset
      end

      context 'when active_document options are provided' do

        before do
          described_class.load!(file)
        end

        it 'sets the include root in json option' do
          expect(described_class.include_root_in_json).to be false
        end

        it 'sets the include type with serialization option' do
          expect(described_class.include_type_for_serialization).to be false
        end

        it 'sets the scope overwrite option' do
          expect(described_class.scope_overwrite_exception).to be false
        end

        it 'sets the preload models option' do
          expect(described_class.preload_models).to be false
        end

        it 'sets the raise not found error option' do
          expect(described_class.raise_not_found_error).to be true
        end

        it 'sets the use utc option' do
          expect(described_class.use_utc).to be false
        end

        it 'sets the join_contexts default option' do
          expect(described_class.join_contexts).to be false
        end
      end

      context 'when client configurations are provided' do

        context 'when a default is provided' do

          before do
            described_class.load!(file, :test_with_max_staleness)
          end

          let(:default) do
            described_class.clients[:default]
          end

          it 'sets the default hosts' do
            expect(default[:hosts]).to eq(SpecConfig.instance.addresses)
            # and make sure the value is not empty
            expect(default[:hosts].first).to include(':')
          end

          context 'when the default has options' do

            let(:options) do
              default['options']
            end

            it 'sets the read option' do
              expect(options['read']).to eq({ 'mode' => :primary_preferred,
                                              'max_staleness' => 100 })
            end
          end
        end
      end
    end

    context 'when schema map is provided with uuid' do
      let(:file) do
        File.join(File.dirname(__FILE__), '..', 'config', 'active_document_with_schema_map_uuid.yml')
      end
      let(:client) { ActiveDocument.default_client }

      before do
        described_class.load!(file, :test)
      end

      it 'passes uuid to driver' do
        expect(Mongo::Client).to receive(:new).with(
          SpecConfig.instance.addresses,
          {
            auto_encryption_options: {
              'key_vault_namespace' => 'admin.datakeys',
              'kms_providers' => { 'local' => { 'key' => 'z7iYiYKLuYymEWtk4kfny1ESBwwFdA58qMqff96A8ghiOcIK75lJGPUIocku8LOFjQuEgeIP4xlln3s7r93FV9J5sAE7zg8U' } },
              'schema_map' => { 'blog_development.comments' => {
                'bsonType' => 'object',
                'properties' => {
                  'message' => { 'encrypt' => {
                    'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic',
                    'bsonType' => 'string',
                    'keyId' => [BSON::Binary.new("G\xF0 5\xCC@HX\xA2%b\x97\xA9a\xA8\xE7", :uuid)]
                  } }
                }
              } }
            },
            database: 'active_document_test',
            platform: "active_document-#{ActiveDocument::VERSION}",
            wrapping_libraries: [
              { 'name' => 'ActiveDocument', 'version' => ActiveDocument::VERSION }
            ]
          }
        )

        client
      end
    end
  end

  describe '#options=' do

    context 'when there are no options' do

      before do
        described_class.options = nil
      end

      it 'does not try to assign options' do
        expect(described_class.preload_models).to be false
      end
    end

    context 'when provided a non-existent option' do

      it 'raises an error' do
        expect do
          described_class.options = { bad_option: true }
        end.to raise_error(ActiveDocument::Errors::InvalidConfigOption)
      end
    end

    context 'when invalid global_executor_concurrency option provided' do
      it 'raises an error' do
        expect do
          described_class.options = {
            async_query_executor: :immediate,
            global_executor_concurrency: 5
          }
        end.to raise_error(ActiveDocument::Errors::InvalidGlobalExecutorConcurrency)
      end
    end
  end

  describe '#clients=' do

    context 'when no clients configuration exists' do

      it 'raises an error' do
        expect do
          described_class.send(:clients=, nil)
        end.to raise_error(ActiveDocument::Errors::NoClientsConfig)
      end
    end

    context 'when no default client exists' do

      it 'raises an error' do
        expect do
          described_class.send(:clients=, {})
        end.to raise_error(ActiveDocument::Errors::NoDefaultClient)
      end
    end

    context 'when a default client exists' do

      context 'when no hosts are provided' do

        let(:clients) do
          { 'default' => { database: database_id } }
        end

        it 'raises an error' do
          expect do
            described_class.send(:clients=, clients)
          end.to raise_error(ActiveDocument::Errors::NoClientHosts)
        end
      end

      context 'when no database is provided' do

        let(:clients) do
          { 'default' => { hosts: ['127.0.0.1:27017'] } }
        end

        it 'raises an error' do
          expect do
            described_class.send(:clients=, clients)
          end.to raise_error(ActiveDocument::Errors::NoClientDatabase)
        end
      end

      context 'when a uri and standard options are provided' do

        let(:clients) do
          {
            'default' => {
              hosts: ['127.0.0.1:27017'],
              uri: 'mongodb://127.0.0.1:27017'
            }
          }
        end

        it 'raises an error' do
          expect do
            described_class.send(:clients=, clients)
          end.to raise_error(ActiveDocument::Errors::MixedClientConfiguration)
        end
      end
    end
  end

  describe '.log_level=' do
    around do |example|
      saved_log_level = described_class.log_level
      begin
        example.run
      ensure
        described_class.log_level = saved_log_level
      end
    end

    it 'accepts a string' do
      described_class.log_level = 'info'
      expect(described_class.log_level).to eq(1)

      # set twice to ensure value changes from default, whatever the default is
      described_class.log_level = 'warn'
      expect(described_class.log_level).to eq(2)
    end

    it 'accepts an integer' do
      described_class.log_level = 1
      expect(described_class.log_level).to eq(1)

      # set twice to ensure value changes from default, whatever the default is
      described_class.log_level = 2
      expect(described_class.log_level).to eq(2)
    end
  end

  describe '#purge!' do

    it 'deletes models' do
      House.create!(name: '1', model: 'Big')
      expect(House.count).to eq(1)
      ActiveDocument.purge!
      expect(House.count).to eq(0)
    end

    it 'drops collections' do
      House.create!(name: '1', model: 'Big')
      Band.create!(name: 'Fleet Foxes')

      client = ActiveDocument.default_client
      expect(client.collections.map(&:name).sort).to eq %w[bands houses]
      ActiveDocument.purge!
      expect(client.collections.map(&:name)).to eq []
    end
  end

  describe '#truncate!' do

    it 'deletes models' do
      House.create!(name: '1', model: 'Big')
      expect(House.count).to eq(1)
      ActiveDocument.truncate!
      expect(House.count).to eq(0)
    end

    it 'does not drop collections' do
      House.create!(name: '1', model: 'Big')
      Band.create!(name: 'Fleet Foxes')

      client = ActiveDocument.default_client
      expect(client.collections.map(&:name).sort).to eq %w[bands houses]
      ActiveDocument.truncate!
      expect(client.collections.map(&:name).sort).to eq %w[bands houses]
    end

    it 'does not drop indexes' do
      User.create_indexes
      expect(User.collection.indexes.pluck('name')).to eq %w[_id_ name_1]
      ActiveDocument.truncate!
      expect(User.collection.indexes.pluck('name')).to eq %w[_id_ name_1]
    end
  end

  describe '#override_database' do
    let(:database) do
      "test_override_#{Time.now.to_i}"
    end

    after do
      # Ensure the database override is cleared.
      ActiveDocument.override_database(nil)
    end

    it 'overrides document querying and persistence' do
      House.create!(name: '1', model: 'Big')
      expect(House.count).to eq(1)

      ActiveDocument.override_database(database)
      expect(House.count).to eq(0)

      expect(Band.count).to eq(0)
      Band.create!(name: 'Wolf Alice')
      expect(Band.count).to eq(1)

      ActiveDocument.override_database(nil)
      expect(House.count).to eq(1)
      expect(Band.count).to eq(0)
    end

    describe '#truncate and #purge' do
      before do
        House.create!(name: '1', model: 'Big')
        expect(House.count).to eq(1)
        ActiveDocument.override_database(database)
      end

      after do
        ActiveDocument.override_database(nil)
        expect(House.count).to eq(1)
      end

      describe '#purge' do
        it 'respects persistence context overrides' do
          House.create!(name: '2', model: 'Tiny')
          expect(House.count).to eq(1)
          ActiveDocument.purge!
          expect(House.count).to eq(0)
        end
      end

      describe '#truncate' do
        it '#truncate! respects persistence context overrides' do
          House.create!(name: '2', model: 'Tiny')
          expect(House.count).to eq(1)
          ActiveDocument.truncate!
          expect(House.count).to eq(0)
        end
      end
    end
  end

  describe '#field_type' do
    around do |example|
      klass = ActiveDocument::Fields::FieldTypes
      klass.instance_variable_set(:@mapping, klass::DEFAULT_MAPPING.dup)
      example.run
      klass.instance_variable_set(:@mapping, klass::DEFAULT_MAPPING.dup)
    end

    it 'can define a custom type' do
      ActiveDocument.configure do |config|
        config.field_type :my_type, Integer
      end

      expect(ActiveDocument::Fields::FieldTypes.get(:my_type)).to eq Integer
    end

    it 'can override and existing type' do
      ActiveDocument.configure do |config|
        config.field_type :integer, String
      end

      expect(ActiveDocument::Fields::FieldTypes.get(:integer)).to eq String
    end
  end

  describe '#field_option method' do
    after do
      ActiveDocument::Fields.instance_variable_set(:@options, {})
    end

    it 'can define a custom field option' do
      ActiveDocument.configure do |config|
        config.field_option :my_required do |model, field, value|
          model.validates_presence_of field.name if value
        end
      end

      klass = Class.new do
        include ActiveDocument::Document
        field :my_field, my_required: true

        def self.model_name
          double('model_name', human: 'Klass')
        end
      end

      instance = klass.new
      expect(instance.valid?).to be false
      expect(instance.errors.full_messages).to eq ["My field can't be blank"]
    end
  end

  describe 'deprecations' do
    {}.each do |option, default|

      context ":#{option} option" do

        before do
          ActiveDocument::Warnings.class_eval do
            instance_variable_set(:"@#{option}_deprecated", false)
          end
        end

        let(:matcher) do
          /Config option :#{option}.+\. It will always be #{default} beginning in ActiveDocument 9\.0\./
        end

        context 'when set to true' do
          it 'gives a deprecation warning' do
            expect(ActiveDocument.logger).to receive(:warn).with(matcher)
            described_class.send(:"#{option}=", true)
          end
        end

        context 'when set to false' do
          it 'gives a deprecation warning' do
            expect(ActiveDocument.logger).to receive(:warn).with(matcher)
            described_class.send(:"#{option}=", false)
          end
        end
      end
    end
  end
end
