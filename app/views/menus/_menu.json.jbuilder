json.extract! menu, :id, :name, :created_at, :updated_at
json.url restaurant_menu_url(menu.restaurant, menu, format: :json)
json.menu_items menu.menu_items do |menu_item|
  json.id menu_item.id
  json.name menu_item.name
  json.price_in_cents menu_item.price_in_cents
  json.url restaurant_menu_menu_item_url(menu.restaurant, menu, menu_item, format: :json)
end
