class ValidateRestaurantData
  include Interactor

  def call
    context.validation_errors = []
    context.logs ||= []

    %w[validate_data_structure validate_restaurants].each do |step|
      send(step)
      return if context.failure?
    end

    context.logs << {
      level: :info,
      message: "Data validation completed successfully"
    }
  end

  private

  def validate_data_structure
    unless context.adapted_data.is_a?(Array)
      context.fail!(
        message: "Invalid data structure: expected array of restaurants",
        logs: [ { level: :error, message: "Adapted data is not an array" } ]
      )
      return
    end

    if context.adapted_data.empty?
      context.fail!(
        message: "No restaurants found in data",
        logs: [ { level: :error, message: "Adapted data array is empty" } ]
      )
    end
  end

  def validate_restaurants
    context.adapted_data.each_with_index do |restaurant_data, index|
      validate_restaurant(restaurant_data, index)
    end

    if context.validation_errors.any?
      context.fail!(
        message: "Validation failed with #{context.validation_errors.size} error(s)",
        validation_errors: context.validation_errors
      )
    end
  end

  def validate_restaurant(restaurant_data, index)
    path = "restaurants[#{index}]"

    add_error(path, "name is required") if restaurant_data[:name].blank?

    unless restaurant_data[:menus].is_a?(Array)
      add_error(path, "menus must be an array")
      return
    end

    if restaurant_data[:menus].empty?
      add_warning(path, "has no menus")
    end

    restaurant_data[:menus].each_with_index do |menu_data, menu_index|
      validate_menu(menu_data, "#{path}.menus[#{menu_index}]")
    end
  end

  def validate_menu(menu_data, path)
    add_error(path, "name is required") if menu_data[:name].blank?

    unless menu_data[:menu_items].is_a?(Array)
      add_error(path, "menu_items must be an array")
      return
    end

    if menu_data[:menu_items].empty?
      add_warning(path, "has no menu items")
    end

    menu_data[:menu_items].each_with_index do |item_data, item_index|
      validate_menu_item(item_data, "#{path}.menu_items[#{item_index}]")
    end
  end

  def validate_menu_item(item_data, path)
    add_error(path, "name is required") if item_data[:name].blank?

    if item_data[:price_in_cents].blank?
      add_error(path, "price is required")
    elsif !item_data[:price_in_cents].is_a?(Integer) || item_data[:price_in_cents] <= 0
      add_error(path, "price must be greater than 0")
    end
  end

  def add_error(path, message)
    context.validation_errors << { path: path, message: message, severity: :error }
    context.logs << { level: :error, message: "#{path}: #{message}" }
  end

  def add_warning(path, message)
    context.validation_errors << { path: path, message: message, severity: :warning }
    context.logs << { level: :warn, message: "#{path}: #{message}" }
  end
end
