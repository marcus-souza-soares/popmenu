FactoryBot.define do
  factory :menu_item do
    association :menu
    name { "Sample Menu Item" }
    price_in_cents { 1299 }
  end
end
