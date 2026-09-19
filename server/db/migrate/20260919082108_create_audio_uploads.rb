class CreateAudioUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :audio_uploads do |t|
      t.string :filename
      t.string :file_hash
      t.float :duration
      t.boolean :is_outlier
      t.integer :bitrate
      t.integer :sample_rate
      t.integer :quality_score
      t.string :storage_path
      t.timestamps
    end
    add_index :audio_uploads, :file_hash
  end
end
