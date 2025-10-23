class RestaurantJsonAdapter
  attr_reader :raw_data, :errors

  def initialize(raw_data)
    @raw_data = raw_data
    @errors = []
  end

  def adapt
    return [] unless raw_data.is_a?(Hash) && raw_data["restaurants"].is_a?(Array)

    raw_data["restaurants"].map.with_index do |restaurant_data, index|
      adapt_restaurant(restaurant_data, index)
    end.compact
  end

  def valid?
    errors.empty?
  end

  private

  def adapt_restaurant(restaurant_data, index)
    unless restaurant_data.is_a?(Hash)
      add_error("restaurants[#{index}]", "must be an object")
      return
    end

    {
      name: restaurant_data["name"],
      menus: adapt_menus(restaurant_data["menus"] || [], "restaurants[#{index}]")
    }
  end

  def adapt_menus(menus_data, parent_path)
    return [] unless menus_data.is_a?(Array)

    menus_data.map.with_index do |menu_data, index|
      adapt_menu(menu_data, "#{parent_path}.menus[#{index}]")
    end.compact
  end

  def adapt_menu(menu_data, path)
    unless menu_data.is_a?(Hash)
      add_error(path, "must be an object")
      return
    end

    items_data = menu_data["menu_items"] || menu_data["dishes"] || []

    {
      name: menu_data["name"],
      menu_items: adapt_menu_items(items_data, path)
    }
  end

  def adapt_menu_items(items_data, parent_path)
    return [] unless items_data.is_a?(Array)

    items_data.map.with_index do |item_data, index|
      adapt_menu_item(item_data, "#{parent_path}.items[#{index}]")
    end.compact
  end

  def adapt_menu_item(item_data, path)
    unless item_data.is_a?(Hash)
      add_error(path, "must be an object")
      return
    end

    price = item_data["price"]
    price_in_cents = price.present? ? convert_price_to_cents(price) : 0

    {
      name: item_data["name"],
      price_in_cents: price_in_cents
    }
  end

  def convert_price_to_cents(price)
    case price
    when Numeric, String
      (price.to_f * 100).to_i
    else
      0
    end
  end

  def add_error(path, message)
    @errors << { path: path, message: message }
  end
end
