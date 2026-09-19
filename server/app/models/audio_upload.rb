# app/models/audio_upload.rb
class AudioUpload < ApplicationRecord
  validates :filename, :file_hash, :duration, :bitrate,
            :sample_rate, :quality_score, :storage_path, presence: true
  validates :file_hash, uniqueness: { message: "has already been processed" }
  validates :duration, numericality: { greater_than: 0 }
  validates :quality_score, inclusion: { in: 1..10, message: "must be a grade between 1 and 10" }
end
