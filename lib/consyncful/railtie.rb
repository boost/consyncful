# frozen_string_literal: true

# Adds Consyncful task to Rails
class Consyncful::Railtie < Rails::Railtie
  rake_tasks do
    load 'consyncful/tasks/consyncful.rake'
  end
end
