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
        duration: formatted_duration,
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

    def formatted_duration
      total_seconds = upload.duration.to_f.round
      minutes = (total_seconds % 3600) / 60
      seconds = total_seconds % 60

      format("%02d:%02d", minutes, seconds)
    end
  end
end
