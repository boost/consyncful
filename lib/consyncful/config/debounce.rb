# frozen_string_literal: true
module Consyncful
  module Config
    class Debounce
      attr_accessor :window_seconds
      def initialize
        @window_seconds = 10
      end
    end
  end
end
