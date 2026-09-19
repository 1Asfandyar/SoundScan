# frozen_string_literal: true

class Api::AudioUploadsController < ApplicationController
  def create
    result = Audio::Analyzer.call(upload_file.fetch(:audio))

    render json: { success: true, result: result }, status: :created
  end

  private

  def upload_file
    params.permit(:audio)
  end
end
