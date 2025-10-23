class ParseJsonData
  include Interactor

  def call
    %w[validate_input parse_json adapt_data].each do |step|
      send(step)
      return if context.failure?
    end
  end

  private

  def validate_input
    return if context.json_content.present?

    context.fail!(
      message: "JSON content is required",
      logs: [{ level: :error, message: "No JSON content provided for parsing" }]
    )
  end

  def parse_json
    context.raw_data = JSON.parse(context.json_content)
    context.logs ||= []
    context.logs << { level: :info, message: "Successfully parsed JSON data" }
  rescue JSON::ParserError => e
    context.fail!(
      message: "Invalid JSON format: #{e.message}",
      logs: [{ level: :error, message: "JSON parsing failed: #{e.message}" }]
    )
  end

  def adapt_data
    adapter = RestaurantJsonAdapter.new(context.raw_data)
    context.adapted_data = adapter.adapt
    context.adapter_errors = adapter.errors

    context.logs ||= []
    if adapter.valid?
      context.logs << {
        level: :info,
        message: "Successfully adapted #{context.adapted_data.size} restaurant(s)"
      }
    else
      context.logs << {
        level: :warn,
        message: "Adapter found #{adapter.errors.size} warning(s) during adaptation"
      }
    end
  end
end
