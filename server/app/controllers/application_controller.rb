class ApplicationController < ActionController::API
  rescue_from AudioUploads::InvalidFileError, with: :unprocessable_entity
  rescue_from AudioUploads::AnalysisError, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :unprocessable_entity
  rescue_from AudioUploads::DuplicateError, with: :render_duplicate_error


  private

  def unprocessable_entity(error)
    render json: { success: false, error: error.message }, status: :unprocessable_entity
  end

  def render_duplicate_error(error)
    render json: { success: false, error: error.message }, status: :conflict
  end
end
