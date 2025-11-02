class ImportResultSerializer
  def initialize(result)
    @result = result
  end

  def success_response
    {
      success: true,
      message: @result.message,
      summary: {
        restaurants: @result.total_restaurants || 0,
        menus: @result.total_menus || 0,
        menu_items: @result.total_menu_items || 0,
        assignments: @result.total_assignments || 0
      },
      results: @result.import_results || [],
      logs: @result.logs || []
    }
  end

  def error_response
    {
      success: false,
      message: @result.message,
      validation_errors: @result.validation_errors || [],
      adapter_errors: @result.adapter_errors || [],
      logs: @result.logs || []
    }
  end
end
