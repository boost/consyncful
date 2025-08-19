# frozen_string_literal: true

module Consyncful
  # The SyncRunner is responsible for continuously executing Contentful sync
  # jobs at a configurable interval or in response to webhook signals.
  #
  # Modes:
  # - :poll    — runs the sync every N seconds (default 15)
  # - :webhook — waits for webhook signals and triggers a sync when received
  #
  # Behavior:
  # - Starts with an initial sync (`Consyncful::Sync.latest.run`).
  # - In poll mode, sleeps for the configured interval and then re-runs sync.
  # - In webhook mode, listens for webhook signals and runs sync immediately.
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
        current_sync.run if @mode == :poll || Consyncful::Sync.consume_webhook_signal!
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
