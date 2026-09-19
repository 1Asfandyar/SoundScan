class AddConstraintsToAudioUploads < ActiveRecord::Migration[8.1]
  def change
    remove_index :audio_uploads, :file_hash if index_exists?(:audio_uploads, :file_hash)
    add_index :audio_uploads, :file_hash, unique: true

    change_column_null :audio_uploads, :filename, false
    change_column_null :audio_uploads, :file_hash, false
    change_column_null :audio_uploads, :duration, false
    change_column_null :audio_uploads, :bitrate, false
    change_column_null :audio_uploads, :sample_rate, false
    change_column_null :audio_uploads, :quality_score, false
    change_column_null :audio_uploads, :storage_path, false
    
    change_column_default :audio_uploads, :is_outlier, from: nil, to: false
    change_column_null :audio_uploads, :is_outlier, false

    add_check_constraint :audio_uploads, "quality_score BETWEEN 1 AND 10", name: "chk_quality_score_range"
    add_check_constraint :audio_uploads, "duration > 5", name: "chk_duration_greater_than_five"
  end
end
