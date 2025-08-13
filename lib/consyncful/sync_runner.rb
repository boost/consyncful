# lib/consyncful/sync_runner.rb
module Consyncful
  class SyncRunner
    DEFAULT_INTERVAL = 15
    VALID_MODES = %i[poll webhook].freeze

    def initialize(seconds: nil, mode: nil, logger: nil)
      @interval = seconds || DEFAULT_INTERVAL
      @mode     = normalize_mode(mode || resolved_mode_from_config_or_env)
      @logger   = logger || Logger.new($stdout).tap { |l| l.progname = "consyncful" }
      @sync     = Consyncful::Sync.latest
      @stop     = false
      @shutdown_reason = nil
    end

    def run
      trap_signals!
      log "mode=#{@mode.inspect} interval=#{@interval}s"

      case @mode
      when :poll    then run_poll
      when :webhook then run_webhook
      end
    ensure
      if @shutdown_reason
        log "Graceful shutdown (#{@shutdown_reason}) PID=#{Process.pid}", level: :warn
      end
    end

    private

    def run_poll
      loop do
        break if @stop
        @sync.run
        sleep(@interval)
      end
    end

    def run_webhook
      @sync.run
      loop do
        break if @stop
        if Consyncful::Sync.consume_webhook_signal!
          @sync.run
        else
          sleep(@interval)
        end
      end
    end

    def normalize_mode(value)
      sym = value.to_sym
      return sym if VALID_MODES.include?(sym)
      raise ArgumentError, "Unknown sync mode: #{sym.inspect} (expected :poll or :webhook)"
    end

    def resolved_mode_from_config_or_env
      if Consyncful.respond_to?(:configuration)
        Consyncful.configuration&.sync_mode || ENV['CONSYNCFUL_SYNC_MODE'] || :poll
      else
        ENV['CONSYNCFUL_SYNC_MODE'] || :poll
      end
    end

    def trap_signals!
      %w[TERM INT].each do |sig|
        Signal.trap(sig) do
          @shutdown_reason ||= sig
          @stop = true
        end
      end
    end

    def log(msg, level: :info)
      case level
      when :warn  then @logger.warn(msg)
      when :error then @logger.error(msg)
      else             @logger.info(msg)
      end
    end
  end
end
