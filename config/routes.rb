Rails.application.routes.draw do
  resources :restaurants do
    resources :menus do
      resources :menu_items, only: [:index, :show, :new, :create, :destroy, :edit]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
