# frozen_string_literal: true
module Consyncful
  module Config
    class Jobs
      attr_accessor :queue
      def initialize
        @queue = :consyncful
      end
    end
  end
end
