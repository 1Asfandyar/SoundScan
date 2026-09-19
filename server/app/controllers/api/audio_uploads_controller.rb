# frozen_string_literal: true

class Api::AudioUploadsController < ApplicationController
  #   rescue_from AudioUploads::InvalidFileError, with: :render_invalid_file
  #   rescue_from AudioUploads::AnalysisError, with: :render_analysis_error

  def create
    result = Audio::Analyzer.call(params[:audio])

    render json: result, status: :created
  end

  private

  def upload_file
    params.permit(:title, :audio)
  end

  def render_invalid_file(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end

  def render_analysis_error(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end
end
