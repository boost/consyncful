# frozen_string_literal: true

module Consyncful
  class Stats
    def initialize
      @stats = {
        records_added: 0,
        records_updated: 0,
        records_deleted: 0
      }
    end

    def record_added
      @stats[:records_added] += 1
    end

    def record_updated
      @stats[:records_updated] += 1
    end

    def record_deleted
      @stats[:records_deleted] += 1
    end

    def print_stats
      puts "Added: #{@stats[:records_added]}, \
        updated:  #{@stats[:records_updated]}, \
        deleted: #{@stats[:records_deleted]}".blue
    end
  end
end
