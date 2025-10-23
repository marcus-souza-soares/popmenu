# Interactor to import restaurant data into the database
# Creates or updates restaurants, menus, and menu items with proper associations
class ImportRestaurantData
  include Interactor

  # Expected context inputs:
  #   - adapted_data: Array (normalized restaurant data)
  #
  # Context outputs:
  #   - import_results: Array (results for each restaurant/menu/item)
  #   - total_restaurants: Integer
  #   - total_menus: Integer
  #   - total_menu_items: Integer
  #   - total_assignments: Integer
  def call
    initialize_counters
    context.import_results = []
    context.logs ||= []

    context.logs << {
      level: :info,
      message: "Starting import of #{context.adapted_data.size} restaurant(s)"
    }

    import_restaurants
    log_summary
  end

  private

  def initialize_counters
    context.total_restaurants = 0
    context.total_menus = 0
    context.total_menu_items = 0
    context.total_assignments = 0
  end

  def import_restaurants
    context.adapted_data.each_with_index do |restaurant_data, index|
      import_restaurant(restaurant_data, index)
    end
  rescue StandardError => e
    context.fail!(
      message: "Import failed: #{e.message}",
      logs: [{ level: :error, message: "Unexpected error during import: #{e.message}\n#{e.backtrace.first(5).join("\n")}" }]
    )
  end

  def import_restaurant(restaurant_data, index)
    restaurant_result = {
      restaurant_name: restaurant_data[:name],
      status: :success,
      menus: []
    }

    ActiveRecord::Base.transaction do
      restaurant = find_or_create_restaurant(restaurant_data[:name])

      if restaurant.persisted?
        context.total_restaurants += 1 if restaurant.previously_new_record?
        restaurant_result[:restaurant_id] = restaurant.id

        restaurant_data[:menus].each do |menu_data|
          menu_result = import_menu(restaurant, menu_data)
          restaurant_result[:menus] << menu_result
        end
      else
        restaurant_result[:status] = :failed
        restaurant_result[:errors] = restaurant.errors.full_messages
        context.logs << {
          level: :error,
          message: "Failed to create restaurant '#{restaurant_data[:name]}': #{restaurant.errors.full_messages.join(', ')}"
        }
      end
    end

    context.import_results << restaurant_result
  rescue StandardError => e
    restaurant_result[:status] = :failed
    restaurant_result[:errors] = [e.message]
    context.import_results << restaurant_result

    context.logs << {
      level: :error,
      message: "Failed to import restaurant '#{restaurant_data[:name]}': #{e.message}"
    }
  end

  def find_or_create_restaurant(name)
    Restaurant.find_or_create_by(name: name)
  end

  def import_menu(restaurant, menu_data)
    menu_result = {
      menu_name: menu_data[:name],
      status: :success,
      menu_items: []
    }

    menu = restaurant.menus.find_or_create_by(name: menu_data[:name])

    if menu.persisted?
      context.total_menus += 1 if menu.previously_new_record?
      menu_result[:menu_id] = menu.id

      menu_data[:menu_items].each do |item_data|
        item_result = import_menu_item(menu, item_data)
        menu_result[:menu_items] << item_result
      end
    else
      menu_result[:status] = :failed
      menu_result[:errors] = menu.errors.full_messages
      context.logs << {
        level: :error,
        message: "Failed to create menu '#{menu_data[:name]}' for restaurant '#{restaurant.name}': #{menu.errors.full_messages.join(', ')}"
      }
    end

    menu_result
  rescue StandardError => e
    menu_result[:status] = :failed
    menu_result[:errors] = [e.message]
    context.logs << {
      level: :error,
      message: "Failed to import menu '#{menu_data[:name]}': #{e.message}"
    }
    menu_result
  end

  def import_menu_item(menu, item_data)
    item_result = {
      item_name: item_data[:name],
      price_in_cents: item_data[:price_in_cents],
      status: :success
    }

    # Find or create the menu item (globally unique by name)
    menu_item = MenuItem.find_by(name: item_data[:name])

    if menu_item
      # Update price if provided and different
      if item_data[:price_in_cents] && menu_item.price_in_cents != item_data[:price_in_cents]
        menu_item.update(price_in_cents: item_data[:price_in_cents])
        item_result[:action] = :updated
      else
        item_result[:action] = :reused
      end
    else
      # Create new menu item
      menu_item = MenuItem.create(
        name: item_data[:name],
        price_in_cents: item_data[:price_in_cents]
      )

      if menu_item.persisted?
        context.total_menu_items += 1
        item_result[:action] = :created
      else
        item_result[:status] = :failed
        item_result[:errors] = menu_item.errors.full_messages
        context.logs << {
          level: :error,
          message: "Failed to create menu item '#{item_data[:name]}': #{menu_item.errors.full_messages.join(', ')}"
        }
        return item_result
      end
    end

    item_result[:menu_item_id] = menu_item.id

    # Create menu assignment (association between menu and menu item)
    assignment = menu.menu_assignments.find_or_create_by(menu_item: menu_item)

    if assignment.persisted?
      context.total_assignments += 1 if assignment.previously_new_record?
      item_result[:assignment_id] = assignment.id
      item_result[:assignment_action] = assignment.previously_new_record? ? :created : :exists

      context.logs << {
        level: :info,
        message: "Menu item '#{item_data[:name]}' #{item_result[:action]} and assigned to menu '#{menu.name}'"
      }
    else
      item_result[:status] = :failed
      item_result[:errors] = assignment.errors.full_messages
      context.logs << {
        level: :error,
        message: "Failed to assign menu item '#{item_data[:name]}' to menu: #{assignment.errors.full_messages.join(', ')}"
      }
    end

    item_result
  rescue StandardError => e
    item_result[:status] = :failed
    item_result[:errors] = [e.message]
    context.logs << {
      level: :error,
      message: "Failed to import menu item '#{item_data[:name]}': #{e.message}"
    }
    item_result
  end

  def log_summary
    context.logs << {
      level: :info,
      message: "Import completed: #{context.total_restaurants} restaurant(s), #{context.total_menus} menu(s), #{context.total_menu_items} menu item(s), #{context.total_assignments} assignment(s)"
    }
  end
end
