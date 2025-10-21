FactoryBot.define do
  factory :menu do
    association :restaurant
    sequence(:name) { |n| "Menu #{n}" }
  end

  factory :sushi_menu, parent: :menu do
    name { "Sushi Menu" }
  end

  factory :dinner_menu, parent: :menu do
    name { "Dinner Menu" }
  end

  factory :lunch_menu, parent: :menu do
    name { "Lunch Menu" }
  end
end
