Rails.application.routes.draw do
  resources :menus do
    resources :menu_items
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
