class ImportsController < ApplicationController
  rescue_from StandardError, with: :handle_standard_error

  def create
    json_content = extract_json_content

    if json_content.blank?
      return render json: {
        success: false,
        message: "No JSON content provided. Please upload a JSON file or send JSON in the request body.",
        logs: [ { level: :error, message: "No JSON content found in request" } ]
      }, status: :unprocessable_entity
    end

    result = ImportRestaurantsFromJson.call(json_content: json_content)

    serializer = ImportResultSerializer.new(result)

    if result.success?
      render json: serializer.success_response, status: :created
    else
      render json: serializer.error_response, status: :unprocessable_entity
    end
  end

  private

  def extract_json_content
    if params[:file].present?
      file = params[:file]
      file.read
    elsif request.content_type == "application/json" && request.raw_post.present?
      request.raw_post
    elsif params[:json_content].present?
      params[:json_content]
    end
  end

  def handle_standard_error(e)
    Rails.logger.error("Unexpected error during import: #{e.message}\n#{e.backtrace.first(10).join("\n")}")

    render json: {
      success: false,
      message: "An unexpected error occurred during import",
      error: e.message,
      logs: [
        {
          level: :error,
          message: "Unexpected error: #{e.message}"
        }
      ]
    }, status: :internal_server_error
  end
end
