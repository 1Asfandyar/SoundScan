# frozen_string_literal: true

class Api::AudioUploadsController < ApplicationController
  rescue_from AudioUploads::InvalidFileError, with: :render_invalid_file
  rescue_from AudioUploads::AnalysisError, with: :render_analysis_error
  rescue_from AudioUploads::DuplicateError, with: :render_duplicate_error

  def create
    result = Audio::Analyzer.call(upload_file[:audio])

    render json: { success: true, result: result }, status: :created
  end

  private

  def upload_file
    params.permit(:title, :audio)
  end

  def render_invalid_file(error)
    render json: { success: false, error: error.message }, status: :unprocessable_entity
  end

  def render_analysis_error(error)
    render json: { success: false, error: error.message }, status: :unprocessable_entity
  end

  def render_duplicate_error(error)
    render json: { success: false, error: error.message }, status: :conflict
  end
end
