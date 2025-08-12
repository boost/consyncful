# frozen_string_literal: true
module Consyncful
  module Config
    class Lock
      attr_accessor :backend, :ttl_seconds
      def initialize
        @backend     = :mongo
        @ttl_seconds = 15 * 60
      end
    end
  end
end
