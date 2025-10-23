class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  RATE_LIMIT_CONFIG = {
    to: 100,
    within: 1.minute,
    store: Rails.cache,
    by: -> { request.domain },
    with: -> { render json: { error: "Too many requests on domain!, Please try after some time" }, status: :too_many_requests }
  }.freeze

  allow_browser versions: :modern
  protect_from_forgery with: :null_session, if: -> { request.format.json? }
  rate_limit **RATE_LIMIT_CONFIG

  private
    def set_restaurant(id:)
      @restaurant = Restaurant.find_by(id:)

      if @restaurant.blank?
        respond_to do |format|
          format.html { redirect_to restaurants_path, alert: "Restaurant not found.", status: :not_found }
          format.json { render json: { error: "Restaurant not found" }, status: :not_found }
        end
      end
    end

    def set_menu(id:)
      @menu = @restaurant.menus.find_by(id:)

      if @menu.blank?
        respond_to do |format|
          format.html { redirect_to restaurant_menus_path(@restaurant), alert: "Menu not found.", status: :not_found }
          format.json { render json: { error: "Menu not found" }, status: :not_found }
        end
      end
    end
end
