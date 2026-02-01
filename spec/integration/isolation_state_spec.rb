# frozen_string_literal: true

require 'spec_helper'

describe 'ActiveDocument::Config.isolation_level' do
  def thread_operation(value)
    Thread.new do
      ActiveDocument::Threaded.stack(:testing) << value
      yield if block_given?
      ActiveDocument::Threaded.stack(:testing)
    end.join.value
  end

  def fiber_operation(value)
    Fiber.new do
      ActiveDocument::Threaded.stack(:testing) << value
      yield if block_given?
      ActiveDocument::Threaded.stack(:testing)
    end.resume
  end

  context 'when set to an unsupported value' do
    it 'raises an error' do
      old_value = ActiveDocument::Config.isolation_level
      expect { ActiveDocument::Config.isolation_level = :unsupported }
        .to raise_error(ActiveDocument::Errors::UnsupportedIsolationLevel)
      expect(ActiveDocument::Config.isolation_level).to eq(old_value)
    end
  end

  context 'when using older Ruby', if: RUBY_VERSION < '3.2' do
    context 'when set to :fiber' do
      it 'raises an error' do
        expect { ActiveDocument::Config.isolation_level = :fiber }
          .to raise_error(ActiveDocument::Errors::UnsupportedIsolationLevel)
      end
    end

    context 'when set to :thread' do
      around do |example|
        save = ActiveDocument::Config.isolation_level
        example.run
      ensure
        ActiveDocument::Config.isolation_level = save
      end

      it 'sets the isolation level' do
        expect { ActiveDocument::Config.isolation_level = :thread }
          .to_not raise_error
        expect(ActiveDocument::Config.isolation_level).to eq(:thread)
      end
    end
  end

  context 'when set to :rails' do
    config_override :isolation_level, :rails

    def self.with_rails_isolation_level(level)
      around do |example|
        # changing the isolation level in Rails apparently can muck with the
        # configured time zone, so we'll save and restore it, too.
        tz_saved = Time.zone

        saved, ActiveSupport::IsolatedExecutionState.isolation_level =
          ActiveSupport::IsolatedExecutionState.isolation_level, level

        example.run
      ensure
        ActiveSupport::IsolatedExecutionState.isolation_level = saved
        Time.zone = tz_saved
      end
    end

    context 'when using Rails < 7', if: !defined?(ActiveSupport::IsolatedExecutionState) do
      it 'returns :thread' do
        expect(ActiveDocument::Config.isolation_level).to eq(:rails)
        expect(ActiveDocument::Config.real_isolation_level).to eq(:thread)
      end
    end

    context 'when using Rails >= 7', if: defined?(ActiveSupport::IsolatedExecutionState) do
      context 'when IsolatedExecutionState.isolation_level is set to :thread' do
        with_rails_isolation_level :thread

        it 'returns :thread' do
          expect(ActiveDocument::Config.isolation_level).to eq(:rails)
          expect(ActiveDocument::Config.real_isolation_level).to eq(:thread)
        end
      end

      context 'when IsolatedExecutionState.isolation_level is set to :fiber' do
        with_rails_isolation_level :fiber

        context 'when Ruby version is >= 3.2', if: RUBY_VERSION >= '3.2' do
          it 'returns :fiber' do
            expect(ActiveDocument::Config.isolation_level).to eq(:rails)
            expect(ActiveDocument::Config.real_isolation_level).to eq(:fiber)
          end
        end

        context 'when Ruby version is < 3.2', if: RUBY_VERSION < '3.2' do
          it 'raises an error' do
            expect(ActiveDocument::Config.isolation_level).to eq(:rails)
            expect { ActiveDocument::Config.real_isolation_level }.to raise_error(ActiveDocument::Errors::UnsupportedIsolationLevel)
          end
        end
      end
    end
  end

  context 'when set to :thread' do
    config_override :isolation_level, :thread

    context 'when not operating inside fibers' do
      let(:result1) { thread_operation('a') { thread_operation('b') } }
      let(:result2) { thread_operation('b') { thread_operation('c') } }

      it 'isolates state per thread' do
        expect(result1).to eq(%w[a])
        expect(result2).to eq(%w[b])
      end
    end

    context 'when operating inside fibers' do
      let(:result) { thread_operation('a') { fiber_operation('b') } }

      it 'exposes the thread state within the fiber' do
        expect(result).to eq(%w[a b])
      end
    end
  end

  context 'when using Ruby 3.2+', if: RUBY_VERSION >= '3.2' do
    context 'when set to :fiber' do
      config_override :isolation_level, :fiber

      context 'when operating inside threads' do
        let(:result) { fiber_operation('a') { thread_operation('b') } }

        it 'exposes the fiber state within the thread' do
          expect(result).to eq(%w[a b])
        end
      end

      context 'when operating in nested fibers' do
        let(:result) { fiber_operation('a') { fiber_operation('b') } }

        it 'propagates fiber state to nested fibers' do
          expect(result).to eq(%w[a b])
        end
      end

      context 'when operating in adjacent fibers' do
        let(:result1) { fiber_operation('a') { fiber_operation('b') } }
        let(:result2) { fiber_operation('c') { fiber_operation('d') } }

        it 'maintains isolation between adjacent fibers' do
          expect(result1).to eq(%w[a b])
          expect(result2).to eq(%w[c d])
        end
      end

      describe '#reset!' do
        context 'when operating in nested fibers' do
          let(:result) do
            fiber_operation('a') do
              ActiveDocument::Threaded.reset!

              # once reset, subsequent nested fibers will each have their own
              # state; they won't touch the reset state here.
              fiber_operation('b')
              fiber_operation('c')

              # If we then add to the stack here, it will be unaffected by
              # the previous fiber operations.
              ActiveDocument::Threaded.stack(:testing) << 'd'
            end
          end

          it 'clears the fiber state' do
            expect(result).to eq(%w[d])
          end
        end
      end
    end
  end
end
