# frozen_string_literal: true

module Audio
  class AnalysisSerializer
    def self.call(upload, outliers:)
      new(upload, outliers).call
    end

    def initialize(upload, outliers)
      @upload = upload
      @outliers = outliers
    end

    def call
      {
        id: upload.id,
        duplicate: false,
        duration_seconds: upload.duration,
        is_outlier: upload.is_outlier,
        outliers: outliers,
        quality_score: upload.quality_score,
        metadata: {
          filename: upload.filename,
          bitrate_kbps: upload.bitrate,
          sample_rate_hz: upload.sample_rate
        }
      }
    end

    private

    attr_reader :upload, :outliers
  end
end
