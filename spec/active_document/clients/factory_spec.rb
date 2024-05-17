# frozen_string_literal: true

require 'spec_helper'

describe ActiveDocument::Clients::Factory do

  shared_examples_for 'includes seed address' do
    let(:configured_address) do
      address = SpecConfig.instance.addresses.first
      address = "#{address}:27017" unless address.include?(':')
      address
    end

    let(:expected_addresses) do
      [
        configured_address,
        configured_address.sub(/\Alocalhost:/, '127.0.0.1:'),
        configured_address.sub(/\A127\.0\.0\.1:/, 'localhost:')
      ].uniq
    end

    it 'includes seed address' do
      ok = cluster_addresses.any? do |address|
        expected_addresses.include?(address)
      end
      expect(ok).to be true
    end
  end

  describe '.create' do

    context 'when provided a name' do

      context 'when the configuration exists' do

        context 'when the configuration is standard' do
          restore_config_clients

          let(:config) do
            {
              default: { hosts: SpecConfig.instance.addresses, database: database_id },
              analytics: { hosts: SpecConfig.instance.addresses, database: database_id }
            }
          end

          let(:cluster_addresses) do
            cluster.addresses.map(&:to_s)
          end

          let(:client) do
            described_class.create(:analytics)
          end

          let(:cluster) do
            client.cluster
          end

          let(:cluster_addresses) do
            cluster.addresses.map(&:to_s)
          end

          before do
            ActiveDocument::Config.send(:clients=, config)
          end

          after do
            client.close
          end

          it 'returns a client' do
            expect(client).to be_a(Mongo::Client)
          end

          context 'on driver versions that do not report spurious EOF errors' do

            it 'does not produce driver warnings' do
              expect(Mongo::Logger.logger).to_not receive(:warn)
              client
            end
          end

          it_behaves_like 'includes seed address'

          it "sets the platform to ActiveDocument's platform constant" do
            expect(client.options[:platform]).to eq(ActiveDocument::PLATFORM_DETAILS)
          end

          it 'sets ActiveDocument as a wrapping library' do
            expect(client.options[:wrapping_libraries]).to eq([BSON::Document.new(
              ActiveDocument::Clients::Factory::MONGOID_WRAPPING_LIBRARY
            )])
          end

          context 'when configuration specifies a wrapping library' do

            let(:config) do
              {
                default: { hosts: SpecConfig.instance.addresses, database: database_id },
                analytics: {
                  hosts: SpecConfig.instance.addresses,
                  database: database_id,
                  options: {
                    wrapping_libraries: [{ name: 'Foo' }]
                  }
                }
              }
            end

            it 'adds ActiveDocument as another wrapping library' do
              expected = [
                BSON::Document.new(ActiveDocument::Clients::Factory::MONGOID_WRAPPING_LIBRARY),
                { 'name' => 'Foo' }
              ]
              expect(client.options[:wrapping_libraries]).to eq(expected)
            end
          end
        end

        context 'when the configuration has no ports' do
          restore_config_clients

          let(:config) do
            {
              default: { hosts: ['127.0.0.1'], database: database_id },
              analytics: { hosts: ['127.0.0.1'], database: database_id }
            }
          end

          let(:client) do
            described_class.create(:analytics)
          end

          let(:default) do
            described_class.create(:default)
          end

          let(:cluster) do
            client.cluster
          end

          before do
            ActiveDocument::Config.send(:clients=, config)
          end

          after do
            client.close
          end

          it 'returns a client' do
            expect(client).to be_a(Mongo::Client)
          end

          it 'sets ips with no ports to 27017' do
            expect(cluster.addresses.first.to_s).to be_in(%w[127.0.0.1:27017 localhost:27017])
          end
        end

        context 'when configured via a uri' do

          context 'when the uri has a single host:port' do
            restore_config_clients

            let(:config) do
              {
                default: { hosts: ['127.0.0.1:27017'], database: database_id },
                analytics: { uri: 'mongodb://127.0.0.1:27017/active_document_test' }
              }
            end

            let(:client) do
              described_class.create(:analytics)
            end

            let(:cluster) do
              client.cluster
            end

            before do
              ActiveDocument::Config.send(:clients=, config)
            end

            after do
              client.close
            end

            it 'returns a client' do
              expect(client).to be_a(Mongo::Client)
            end

            it "sets the cluster's seeds" do
              expect(cluster.addresses.first.to_s).to be_in(%w[127.0.0.1:27017 localhost:27017])
            end

            it 'sets the database' do
              expect(client.options[:database]).to eq('active_document_test')
            end
          end

          context 'when the uri has multiple host:port pairs' do
            restore_config_clients

            let(:config) do
              {
                default: { hosts: ['127.0.0.1:1234'], database: database_id, server_selection_timeout: 1 },
                analytics: { uri: 'mongodb://127.0.0.1:1234,127.0.0.1:5678/active_document_test?serverSelectionTimeoutMS=1000' }
              }
            end
            let(:client) do
              described_class.create(:analytics)
            end
            let(:cluster) do
              client.cluster
            end
            let(:seeds) do
              cluster.addresses.map(&:to_s)
            end

            before do
              ActiveDocument::Config.send(:clients=, config)
            end

            after do
              client.close
            end

            it 'returns a client' do
              expect(client).to be_a(Mongo::Client)
            end

            it "sets the cluster's seeds" do
              expect(seeds).to eq(['127.0.0.1:1234', '127.0.0.1:5678'])
            end
          end
        end
      end

      context 'when the configuration does not exist' do

        it 'raises an error' do
          expect do
            described_class.create(:unknown)
          end.to raise_error(ActiveDocument::Errors::NoClientConfig)
        end
      end

      context 'when auto_encryption_options are provided' do
        require_enterprise
        require_libmongocrypt
        restore_config_clients
        include_context 'with encryption'

        before do
          ActiveDocument::Config.send(:clients=, config)
          key_vault_client[key_vault_collection].drop
        end

        after do
          client.close
        end

        let(:client) do
          described_class.create(:encrypted)
        end

        context 'when no key vault client is provided' do
          let(:config) do
            {
              default: { hosts: SpecConfig.instance.addresses, database: database_id },
              encrypted: {
                hosts: SpecConfig.instance.addresses,
                database: database_id,
                options: {
                  auto_encryption_options: {
                    kms_providers: kms_providers,
                    key_vault_namespace: key_vault_namespace,
                    extra_options: extra_options
                  }
                }
              }
            }
          end

          it 'returns a client' do
            expect(client).to be_a(Mongo::Client)
          end

          it 'sets schema_map for the client' do
            expect(client.options[:auto_encryption_options][:schema_map]).to_not be_nil
          end
        end

        context 'when a key vault client is provided' do
          let(:config) do
            {
              default: { hosts: SpecConfig.instance.addresses, database: database_id },
              key_vault: { hosts: SpecConfig.instance.addresses, database: database_id },
              encrypted: {
                hosts: SpecConfig.instance.addresses,
                database: database_id,
                options: {
                  auto_encryption_options: {
                    key_vault_client: :key_vault,
                    kms_providers: kms_providers,
                    key_vault_namespace: key_vault_namespace,
                    extra_options: extra_options
                  }
                }
              }
            }
          end

          it 'returns a client' do
            expect(client).to be_a(Mongo::Client)
          end

          it 'sets key_vault_client option for the client' do
            expect(client.options[:auto_encryption_options][:key_vault_client]).to eq(ActiveDocument::Clients.with_name(:key_vault))
          end
        end
      end
    end

    context 'when no name is provided' do
      restore_config_clients

      let(:config) do
        { default: { hosts: SpecConfig.instance.addresses, database: database_id } }
      end

      let(:client) do
        described_class.create
      end

      let(:cluster) do
        client.cluster
      end

      let(:cluster_addresses) do
        cluster.addresses.map(&:to_s)
      end

      before do
        ActiveDocument::Config.send(:clients=, config)
      end

      after do
        client.close
      end

      it 'returns the default client' do
        expect(client).to be_a(Mongo::Client)
      end

      it_behaves_like 'includes seed address'
    end

    context 'when nil is provided and no default config' do
      restore_config_clients

      let(:config) { nil }

      before do
        ActiveDocument.clients[:default] = nil
      end

      it 'raises NoClientsConfig error' do
        expect { described_class.create(config) }.to raise_error(ActiveDocument::Errors::NoClientsConfig)
      end
    end
  end

  describe '.default' do
    restore_config_clients

    let(:config) do
      { default: { hosts: SpecConfig.instance.addresses, database: database_id } }
    end
    let(:client) do
      described_class.default
    end
    let(:cluster) do
      client.cluster
    end
    let(:cluster_addresses) do
      cluster.addresses.map(&:to_s)
    end

    before do
      ActiveDocument::Config.send(:clients=, config)
    end

    after do
      client.close
    end

    it 'returns the default client' do
      expect(client).to be_a(Mongo::Client)
    end

    it_behaves_like 'includes seed address'
  end

  context 'when options are provided with string keys' do
    restore_config_clients

    let(:config) do
      {
        default: {
          hosts: SpecConfig.instance.addresses,
          database: database_id,
          options: {
            'server_selection_timeout' => 10,
            'write' => { 'w' => 1 }
          }
        }
      }
    end

    let(:client) do
      described_class.default
    end

    let(:cluster) do
      client.cluster
    end

    let(:cluster_addresses) do
      cluster.addresses.map(&:to_s)
    end

    before do
      ActiveDocument::Config.send(:clients=, config)
    end

    after do
      client.close
    end

    it 'returns the default client' do
      expect(client).to be_a(Mongo::Client)
    end

    it_behaves_like 'includes seed address'

    it 'sets the server selection timeout' do
      expect(cluster.options[:server_selection_timeout]).to eq(10)
    end

    it 'sets the write concern' do
      expect(client.write_concern).to be_a(Mongo::WriteConcern::Acknowledged)
    end

    it "sets the platform to ActiveDocument's platform constant" do
      expect(client.options[:platform]).to eq(ActiveDocument::PLATFORM_DETAILS)
    end
  end

  context 'unexpected config options' do
    restore_config_clients

    let(:unknown_opts) do
      {
        bad_one: 1,
        another_one: 'here'
      }
    end

    let(:config) do
      {
        default: { hosts: SpecConfig.instance.addresses, database: database_id },
        good_one: { hosts: ['127.0.0.1:1234'], database: database_id },
        bad_one: { hosts: ['127.0.0.1:1234'], database: database_id }.merge(unknown_opts),
        good_two: { uri: "mongodb://127.0.0.1:1234,127.0.0.1:5678/#{database_id}" },
        bad_two: { uri: "mongodb://127.0.0.1:1234,127.0.0.1:5678/#{database_id}" }.merge(unknown_opts)
      }
    end

    before do
      ActiveDocument::Config.send(:clients=, config)
    end

    %i[good_one good_two].each do |env|
      it 'does not log a warning if none' do
        expect(described_class.send(:default_logger)).to_not receive(:warn)
        described_class.create(env).close
      end
    end

    %i[bad_one bad_two].each do |env|
      it 'logs a warning if some' do
        expect(described_class.send(:default_logger)).to_not receive(:warn)
        described_class.create(env).close
      end
    end
  end
end
