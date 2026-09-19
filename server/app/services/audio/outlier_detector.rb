# frozen_string_literal: true

module Audio
  class OutlierDetector
    def self.call(metadata)
      new(metadata).call
    end

    def initialize(metadata)
      @metadata = metadata
    end

    def call
      score, active_outliers = evaluate_outliers

      {
        score: score,
        outliers: active_outliers.map { |rule| rule[:code] }
      }
    end

    private

    attr_reader :metadata

    def evaluate_outliers
      critical_outlier = OutlierRules::CRITICAL.find { |rule| rule[:applies].call(metadata) }
      active_outliers = if critical_outlier
                          [ critical_outlier ]
      else
                          OutlierRules::MODERATE.select { |rule| rule[:applies].call(metadata) }
      end

      total_penalty =  active_outliers.sum { |rule| rule[:penalty] || 0 }
      score = 10 - total_penalty
      [ score, active_outliers ]
    end
  end
end
