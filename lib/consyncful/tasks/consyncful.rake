# frozen_string_literal: true

namespace :consyncful do
  desc "Run a one-time sync of the latest Contentful data into the app"
  task update: [:environment] do
    Consyncful::Sync.latest.run
  end

  desc "Run a one-time full refresh of all Contentful data into the app (bypasses caching)"
  task refresh: [:environment] do
    Consyncful::Sync.fresh.run
  end

  desc "Continuously sync Contentful data. Default: poll every N seconds (default: 15)." \
       "Usage: rake consyncful:sync[SECONDS]  |  Modes: poll (default) or webhook"
  task :sync, [:seconds] => %i[environment update_model_names] do |_task, args|
    Signal.trap('TERM') do
      puts Rainbow("Graceful shutdown PID=#{Process.pid}").red
      exit 0
    end

    # interval: in poll mode it's the poll interval; in webhook mode it's the check interval
    seconds = args[:seconds].to_i
    seconds = 15 if seconds.zero?

    # mode comes from config (preferred) or ENV fallback; default :poll
    config  = Consyncful.respond_to?(:configuration) ? Consyncful.configuration : nil
    mode = (config&.sync_mode || ENV['CONSYNCFUL_SYNC_MODE'] || :poll).to_sym

    case mode
    when :poll
      puts "[consyncful] mode=:poll interval=#{seconds}s"
      loop do
        Consyncful::Sync.latest.run
        sleep(seconds)
      end
    when :webhook
      puts "[consyncful] mode=:webhook check_every=#{seconds}s"
      loop do
        # Only run when a webhook has set the boolean; consume it atomically
        if Consyncful::Sync.consume_webhook_signal!
          Consyncful::Sync.latest.run
        else
          sleep(seconds)
        end
      end

    else
      raise "Unknown sync mode: #{mode.inspect} (expected :poll or :webhook)"
    end
  end


  desc "Update stored model_type fields based on Contentful type mappings"
  task update_model_names: [:environment] do
    if Rails.autoloaders.zeitwerk_enabled?
      Zeitwerk::Loader.eager_load_all
    else
      Rails.application.eager_load!
    end

    puts Rainbow('Updating model names:').blue

    Consyncful::Base.model_map.each do |contentful_name, constant|
      puts Rainbow("#{contentful_name}: #{constant}").yellow
      Consyncful::Base.where(contentful_type: contentful_name).update_all(_type: constant.to_s)
    end

    Consyncful::Base.where(:contentful_type.nin => Consyncful::Base.model_map.keys).update_all(_type: 'Consyncful::Base')
  end
end
