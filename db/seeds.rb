return if Rails.env.production?

puts "🌱 Seeding database..."

MenuAssignment.destroy_all
MenuItem.destroy_all
Menu.destroy_all
Restaurant.destroy_all

puts "Creating restaurants..."

tasty_bites = Restaurant.create!(name: "Tasty Bites")
ocean_grill = Restaurant.create!(name: "Ocean Grill & Bar")
bella_italia = Restaurant.create!(name: "Bella Italia")

puts "✅ Created #{Restaurant.count} restaurants"

puts "Creating menus for Tasty Bites..."
tb_breakfast = tasty_bites.menus.create!(name: "Breakfast Menu")
tb_lunch = tasty_bites.menus.create!(name: "Lunch Menu")
tb_dinner = tasty_bites.menus.create!(name: "Dinner Menu")
tb_kids = tasty_bites.menus.create!(name: "Kids Menu")

og_lunch = ocean_grill.menus.create!(name: "Lunch Specials")
og_dinner = ocean_grill.menus.create!(name: "Dinner Menu")
og_drinks = ocean_grill.menus.create!(name: "Drinks & Cocktails")

bi_lunch = bella_italia.menus.create!(name: "Pranzo (Lunch)")
bi_dinner = bella_italia.menus.create!(name: "Cena (Dinner)")
bi_desserts = bella_italia.menus.create!(name: "Dolci (Desserts)")

puts "✅ Created #{Menu.count} menus"

puts "Creating menu items..."

# Breakfast Items
pancakes = MenuItem.create!(name: "Buttermilk Pancakes", price_in_cents: 899)
french_toast = MenuItem.create!(name: "French Toast", price_in_cents: 949)
eggs_benedict = MenuItem.create!(name: "Eggs Benedict", price_in_cents: 1299)
omelette = MenuItem.create!(name: "Veggie Omelette", price_in_cents: 1099)
breakfast_burrito = MenuItem.create!(name: "Breakfast Burrito", price_in_cents: 1199)

# Lunch/Dinner Items
burger = MenuItem.create!(name: "Classic Burger", price_in_cents: 1299)
cheeseburger = MenuItem.create!(name: "Bacon Cheeseburger", price_in_cents: 1499)
caesar_salad = MenuItem.create!(name: "Caesar Salad", price_in_cents: 899)
grilled_chicken = MenuItem.create!(name: "Grilled Chicken Breast", price_in_cents: 1599)
fish_chips = MenuItem.create!(name: "Fish & Chips", price_in_cents: 1399)
ribeye_steak = MenuItem.create!(name: "Ribeye Steak", price_in_cents: 2899)

# Seafood Items
grilled_salmon = MenuItem.create!(name: "Grilled Salmon", price_in_cents: 2199)
shrimp_scampi = MenuItem.create!(name: "Shrimp Scampi", price_in_cents: 1899)
lobster_tail = MenuItem.create!(name: "Lobster Tail", price_in_cents: 3499)
fish_tacos = MenuItem.create!(name: "Fish Tacos", price_in_cents: 1299)
clam_chowder = MenuItem.create!(name: "New England Clam Chowder", price_in_cents: 799)

# Italian Items
margherita_pizza = MenuItem.create!(name: "Margherita Pizza", price_in_cents: 1499)
pepperoni_pizza = MenuItem.create!(name: "Pepperoni Pizza", price_in_cents: 1699)
spaghetti_carbonara = MenuItem.create!(name: "Spaghetti Carbonara", price_in_cents: 1599)
fettuccine_alfredo = MenuItem.create!(name: "Fettuccine Alfredo", price_in_cents: 1499)
lasagna = MenuItem.create!(name: "Homemade Lasagna", price_in_cents: 1799)
risotto = MenuItem.create!(name: "Mushroom Risotto", price_in_cents: 1699)
caprese_salad = MenuItem.create!(name: "Caprese Salad", price_in_cents: 999)

# Desserts
tiramisu = MenuItem.create!(name: "Tiramisu", price_in_cents: 799)
cheesecake = MenuItem.create!(name: "New York Cheesecake", price_in_cents: 699)
gelato = MenuItem.create!(name: "Gelato", price_in_cents: 599)
brownie = MenuItem.create!(name: "Chocolate Brownie", price_in_cents: 649)

# Drinks
coffee = MenuItem.create!(name: "Coffee", price_in_cents: 299)
lemonade = MenuItem.create!(name: "Fresh Lemonade", price_in_cents: 399)
mojito = MenuItem.create!(name: "Mojito", price_in_cents: 899)
margarita = MenuItem.create!(name: "Margarita", price_in_cents: 999)
wine_red = MenuItem.create!(name: "House Red Wine", price_in_cents: 799)
wine_white = MenuItem.create!(name: "House White Wine", price_in_cents: 799)

# Kids Items
kids_burger = MenuItem.create!(name: "Kids Burger", price_in_cents: 699)
kids_pasta = MenuItem.create!(name: "Kids Pasta", price_in_cents: 599)
chicken_nuggets = MenuItem.create!(name: "Chicken Nuggets", price_in_cents: 649)
grilled_cheese = MenuItem.create!(name: "Grilled Cheese Sandwich", price_in_cents: 549)

puts "✅ Created #{MenuItem.count} menu items"

puts "Assigning items to menus..."

# Tasty Bites - Breakfast Menu
MenuAssignment.create!(menu: tb_breakfast, menu_item: pancakes)
MenuAssignment.create!(menu: tb_breakfast, menu_item: french_toast)
MenuAssignment.create!(menu: tb_breakfast, menu_item: eggs_benedict)
MenuAssignment.create!(menu: tb_breakfast, menu_item: omelette)
MenuAssignment.create!(menu: tb_breakfast, menu_item: breakfast_burrito)
MenuAssignment.create!(menu: tb_breakfast, menu_item: coffee)

# Tasty Bites - Lunch Menu
MenuAssignment.create!(menu: tb_lunch, menu_item: burger)
MenuAssignment.create!(menu: tb_lunch, menu_item: cheeseburger)
MenuAssignment.create!(menu: tb_lunch, menu_item: caesar_salad)
MenuAssignment.create!(menu: tb_lunch, menu_item: grilled_chicken)
MenuAssignment.create!(menu: tb_lunch, menu_item: fish_chips)
MenuAssignment.create!(menu: tb_lunch, menu_item: fish_tacos)
MenuAssignment.create!(menu: tb_lunch, menu_item: lemonade)

# Tasty Bites - Dinner Menu (reusing some lunch items + adding premium items)
MenuAssignment.create!(menu: tb_dinner, menu_item: burger)
MenuAssignment.create!(menu: tb_dinner, menu_item: cheeseburger)
MenuAssignment.create!(menu: tb_dinner, menu_item: grilled_chicken)
MenuAssignment.create!(menu: tb_dinner, menu_item: ribeye_steak)
MenuAssignment.create!(menu: tb_dinner, menu_item: grilled_salmon)
MenuAssignment.create!(menu: tb_dinner, menu_item: caesar_salad)
MenuAssignment.create!(menu: tb_dinner, menu_item: cheesecake)
MenuAssignment.create!(menu: tb_dinner, menu_item: brownie)

MenuAssignment.create!(menu: tb_kids, menu_item: kids_burger)
MenuAssignment.create!(menu: tb_kids, menu_item: kids_pasta)
MenuAssignment.create!(menu: tb_kids, menu_item: chicken_nuggets)
MenuAssignment.create!(menu: tb_kids, menu_item: grilled_cheese)
MenuAssignment.create!(menu: tb_kids, menu_item: lemonade)

MenuAssignment.create!(menu: og_lunch, menu_item: fish_tacos)
MenuAssignment.create!(menu: og_lunch, menu_item: caesar_salad)
MenuAssignment.create!(menu: og_lunch, menu_item: clam_chowder)
MenuAssignment.create!(menu: og_lunch, menu_item: fish_chips)
MenuAssignment.create!(menu: og_lunch, menu_item: grilled_salmon)
MenuAssignment.create!(menu: og_lunch, menu_item: lemonade)

MenuAssignment.create!(menu: og_dinner, menu_item: grilled_salmon)
MenuAssignment.create!(menu: og_dinner, menu_item: shrimp_scampi)
MenuAssignment.create!(menu: og_dinner, menu_item: lobster_tail)
MenuAssignment.create!(menu: og_dinner, menu_item: ribeye_steak)
MenuAssignment.create!(menu: og_dinner, menu_item: clam_chowder)
MenuAssignment.create!(menu: og_dinner, menu_item: caesar_salad)
MenuAssignment.create!(menu: og_dinner, menu_item: cheesecake)

MenuAssignment.create!(menu: og_drinks, menu_item: mojito)
MenuAssignment.create!(menu: og_drinks, menu_item: margarita)
MenuAssignment.create!(menu: og_drinks, menu_item: wine_red)
MenuAssignment.create!(menu: og_drinks, menu_item: wine_white)
MenuAssignment.create!(menu: og_drinks, menu_item: lemonade)
MenuAssignment.create!(menu: og_drinks, menu_item: coffee)

MenuAssignment.create!(menu: bi_lunch, menu_item: margherita_pizza)
MenuAssignment.create!(menu: bi_lunch, menu_item: pepperoni_pizza)
MenuAssignment.create!(menu: bi_lunch, menu_item: spaghetti_carbonara)
MenuAssignment.create!(menu: bi_lunch, menu_item: caprese_salad)
MenuAssignment.create!(menu: bi_lunch, menu_item: coffee)

MenuAssignment.create!(menu: bi_dinner, menu_item: margherita_pizza)
MenuAssignment.create!(menu: bi_dinner, menu_item: pepperoni_pizza)
MenuAssignment.create!(menu: bi_dinner, menu_item: spaghetti_carbonara)
MenuAssignment.create!(menu: bi_dinner, menu_item: fettuccine_alfredo)
MenuAssignment.create!(menu: bi_dinner, menu_item: lasagna)
MenuAssignment.create!(menu: bi_dinner, menu_item: risotto)
MenuAssignment.create!(menu: bi_dinner, menu_item: caprese_salad)
MenuAssignment.create!(menu: bi_dinner, menu_item: wine_red)
MenuAssignment.create!(menu: bi_dinner, menu_item: wine_white)

MenuAssignment.create!(menu: bi_desserts, menu_item: tiramisu)
MenuAssignment.create!(menu: bi_desserts, menu_item: gelato)
MenuAssignment.create!(menu: bi_desserts, menu_item: cheesecake)
MenuAssignment.create!(menu: bi_desserts, menu_item: coffee)

puts "✅ Created #{MenuAssignment.count} menu assignments"

puts "\n🎉 Seeding completed successfully!"
puts "\n📊 Summary:"
puts "  • #{Restaurant.count} restaurants"
puts "  • #{Menu.count} menus"
puts "  • #{MenuItem.count} unique menu items"
puts "  • #{MenuAssignment.count} menu item placements"

puts "\n🍽️  Restaurants:"
Restaurant.all.each do |restaurant|
  puts "\n  #{restaurant.name}"
  restaurant.menus.each do |menu|
    puts "    └─ #{menu.name} (#{menu.menu_items.count} items)"
  end
end

puts "\n✨ Example of item reusability:"
shared_items = MenuItem.joins(:menu_assignments).group("menu_items.id").having("COUNT(menu_assignments.id) > 1")
puts "  #{shared_items.count} items appear on multiple menus:"
shared_items.limit(5).each do |item|
  menu_count = item.menu_assignments.count
  puts "    • '#{item.name}' appears on #{menu_count} menus"
end

puts "\n🚀 Ready to go! Try accessing:"
puts "  • http://localhost:3000/restaurants"
puts "  • http://localhost:3000/restaurants.json"
