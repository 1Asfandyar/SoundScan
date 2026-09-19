class ApplicationController < ActionController::API
  rescue_from AudioUploads::InvalidFileError, with: :render_invalid_file
  rescue_from AudioUploads::AnalysisError, with: :render_analysis_error
  rescue_from AudioUploads::DuplicateError, with: :render_duplicate_error

  private

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
