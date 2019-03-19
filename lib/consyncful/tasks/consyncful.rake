# frozen_string_literal: true

namespace :consyncful do
  task update: [:environment] do
    Consyncful::Sync.latest.run
  end

  task refresh: [:environment] do
    Consyncful::Sync.fresh.run
  end

  task :sync, [:seconds] => [:environment, :update_model_names] do |task, args|
    seconds = args[:seconds].to_i
    seconds = 15 if seconds.zero?
    loop do
      Consyncful::Sync.latest.run
      sleep(seconds)
    end
  end

  task update_model_names: [:environment] do
    Rails.application.eager_load!
    puts 'Updating model names:'.blue
    Consyncful::Base.model_map.each do |contentful_name, constant|
      puts "#{contentful_name}: #{constant}".yellow
      Consyncful::Base.where(contentful_type: contentful_name).update_all(_type: constant.to_s)
    end
    Consyncful::Base.where(:contentful_type.nin => Consyncful::Base.model_map.keys).update_all(_type: 'Consyncful::Base')
  end
end