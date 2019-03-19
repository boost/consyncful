# frozen_string_literal: true

class Consyncful::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/consyncful.rake'
  end
end
