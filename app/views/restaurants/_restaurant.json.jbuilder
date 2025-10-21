json.extract! restaurant, :id, :name, :created_at, :updated_at
json.url restaurant_url(restaurant, format: :json)
json.menus restaurant.menus do |menu|
  json.id menu.id
  json.name menu.name
  json.url restaurant_menu_url(restaurant, menu, format: :json)
end
