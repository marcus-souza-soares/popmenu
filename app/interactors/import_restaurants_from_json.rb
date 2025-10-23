class ImportRestaurantsFromJson
  include Interactor::Organizer

  organize ParseJsonData,
           ValidateRestaurantData,
           ImportRestaurantData

  def self.call(context = {})
    result = super

    result.logs ||= []

    if result.success?
      result.message ||= "Import completed successfully"
      result.logs << {
        level: :info,
        message: result.message
      }
    else
      result.message ||= "Import failed"
      result.logs << {
        level: :error,
        message: result.message
      }
    end

    result
  end
end
