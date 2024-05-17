# frozen_string_literal: true

require 'spec_helper'
require 'active_document/railties/console_sandbox'

describe 'console_sandbox' do
  describe '#check_if_transactions_might_be_available!' do
    context 'cluster may support transactions' do
      require_topology :replica_set, :sharded, :load_balanced

      it 'does not raise' do
        expect do
          check_if_transactions_might_be_available!(ActiveDocument.default_client)
        end.to_not raise_error
      end
    end

    context 'cluster does not support transactions' do
      require_topology :single

      it 'raises an error' do
        expect do
          check_if_transactions_might_be_available!(ActiveDocument.default_client)
        end.to raise_error(ActiveDocument::Errors::TransactionsNotSupported)
      end
    end
  end

  describe '#start_sandbox_transaction' do
    require_transaction_support

    before do
      start_sandbox_transaction(ActiveDocument.default_client)
    end

    after do
      ActiveDocument.send(:_session).abort_transaction
      ActiveDocument::Threaded.clear_session(client: ActiveDocument.default_client)
    end

    it 'starts transaction' do
      expect(ActiveDocument.send(:_session)).to be_in_transaction
    end
  end
end
