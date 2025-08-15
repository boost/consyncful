# frozen_string_literal: true

# lib/consyncful/sync_runner.rb
module Consyncful
  class SyncRunner
    DEFAULT_INTERVAL = 15
    VALID_MODES = %i[poll webhook].freeze

    def initialize(seconds: nil, mode: nil)
      @interval = seconds || DEFAULT_INTERVAL
      @mode     = validate_mode(mode)
    end

    def run
      current_sync = Consyncful::Sync.latest
      current_sync.run # Run initial sync

      loop do
        sleep(@interval)
        if @mode == :poll || Consyncful::Sync.consume_webhook_signal!
          current_sync.run
        end
      end
    end

    private

    def validate_mode(value)
      sym = value.to_sym
      return sym if VALID_MODES.include?(sym)

      raise ArgumentError, "Unknown sync mode: #{sym.inspect} (expected :poll or :webhook)"
    end
  end
end
