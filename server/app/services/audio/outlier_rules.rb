# frozen_string_literal: true

module Audio
  module OutlierRules
    CRITICAL = [
      {
        code: :duration_out_of_range,
        applies: ->(metadata) { metadata.length.present? && (metadata.length < 5 || metadata.length > 900) },
        penalty: 9
      },
      {
        code: :bitrate_unusually_high,
        applies: ->(metadata) { metadata.header[:bitrate].present? && metadata.header[:bitrate] > 340 },
        penalty: 9
      }
    ].freeze

    MODERATE = [
      {
        code: :bitrate_too_low,
        penalty: 4,
        applies: ->(metadata) { metadata.header[:bitrate].present? && metadata.header[:bitrate] < 96 }
      },
      {
        code: :sample_rate_too_low,
        penalty: 3,
        applies: ->(metadata) { metadata.header[:samplerate].present? && metadata.header[:samplerate] < 3200 }
      }
    ].freeze
  end
end
