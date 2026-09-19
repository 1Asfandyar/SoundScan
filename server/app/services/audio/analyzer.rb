# frozen_string_literal: true

require "digest"
require "mp3info"

module Audio
  class Analyzer
    def self.call(audio_file)
      new(audio_file).analyze
    end

    def initialize(audio_file)
      @audio_file = audio_file
      @tempfile_path = audio_file.tempfile.path
    end

    def analyze
      @metadata = extract_audio_metadata
      validate_audio_file
      check_if_duplicate

      check_if_outlier
      AnalysisSerializer.call(save_analysis, outliers: @outliers)
    end

    private

    def extract_audio_metadata
      Mp3Info.open(@tempfile_path) do |mp3|
        mp3
      end
    rescue StandardError => error
      raise AudioUploads::AnalysisError, error.message
    end

    def validate_audio_file
      raise AudioUploads::InvalidFileError, "Audio file is required" unless valid_mp3_structure?
    end

    def valid_mp3_structure?
      return false unless @audio_file.original_filename.downcase.end_with?(".mp3")
      return false if @metadata.header[:emphasis] == 3 
      return false if @metadata.header[:layer] != 3

      true
    end

    def check_if_duplicate
      @file_hash = Digest::SHA256.file(@tempfile_path).hexdigest
      raise AudioUploads::DuplicateError, "Duplicate file upload detected" if AudioUpload.exists?(file_hash: @file_hash)
    end

    def check_if_outlier
      outlier_result = Audio::OutlierDetector.call(@metadata)

      @quality_score = outlier_result[:score]
      @outliers = outlier_result[:outliers]
    end

    def save_analysis
      AudioUpload.create!(
        filename: @audio_file.original_filename,
        file_hash: @file_hash,
        duration: @metadata.length,
        bitrate: @metadata.header[:bitrate],
        sample_rate: @metadata.header[:samplerate],
        quality_score: @quality_score,
        storage_path: @tempfile_path,
        is_outlier: @outliers.any?
      )
    rescue ActiveRecord::ActiveRecordError => error
      raise AudioUploads::AnalysisError, error.message
    end
  end
end
