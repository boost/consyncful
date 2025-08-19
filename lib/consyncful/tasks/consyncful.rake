# frozen_string_literal: true

namespace :consyncful do
  desc 'Run a one-time sync of the latest Contentful data into the app'
  task update: [:environment] do
    Consyncful::Sync.latest.run
  end

  desc 'Run a one-time full refresh of all Contentful data into the app (bypasses caching)'
  task refresh: [:environment] do
    Consyncful::Sync.fresh.run
  end

  desc 'Continuously sync Contentful data. Default: poll every N seconds (default: 15)'
  task :sync, [:seconds] => %i[environment update_model_names] do |_task, args|
    require 'consyncful/sync_runner'
    Signal.trap('TERM') do
      puts Rainbow("Graceful shutdown PID=#{Process.pid}").red
      exit 0
    end

    seconds = args[:seconds]
    mode = Consyncful.configuration&.sync_mode || :poll
    puts "mode=#{mode.inspect} interval=#{seconds.inspect}s"

    Consyncful::SyncRunner.new(seconds: seconds, mode: mode).run
  end

  desc 'Update stored model_type fields based on Contentful type mappings'
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
