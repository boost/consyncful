# frozen_string_literal: true

module Consyncful
  # Rails engine for Consyncful.
  #
  # This isolates the Consyncful namespace and allows the gem
  # to provide its own routes, controllers, and configuration
  # within a Rails application without clashing with the host app.
  class Engine < ::Rails::Engine
    isolate_namespace Consyncful
  end
end
