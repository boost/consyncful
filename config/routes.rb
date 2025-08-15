# frozen_string_literal: true

Consyncful::Engine.routes.draw do
  post '/webhook', to: 'webhook#trigger_sync'
end
