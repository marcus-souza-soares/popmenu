Rails.application.routes.draw do
  # Import endpoint for restaurant data
  post "imports/restaurants", to: "imports#create", as: :import_restaurants

  resources :restaurants do
    resources :menus do
      resources :menu_items, only: [ :index, :show, :new, :create, :destroy, :edit ]
    end
  end

  root "restaurants#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
