class MenuItemsController < ApplicationController
  before_action :set_restaurant
  before_action :set_menu
  before_action :set_menu_item, only: %i[ show destroy ]

  # GET /restaurants/:restaurant_id/menus/:menu_id/menu_items or /restaurats/:restaurant_id/menus/:menu_id/menu_items.json
  def index
    @menu_items = @menu.menu_items
  end

  def show
  end

  # GET /restaurants/:restaurant_id/menus/:menu_id/menu_items/new
  def new
    @menu_item = MenuItem.new
  end

  # GET /restaurants/:restaurant_id/menus/:menu_id/menu_items/1/edit
  def edit; end

  # POST /restaurants/:restaurant_id/menus/:menu_id/menu_items or /restaurants/:restaurant_id/menus/:menu_id/menu_items.json
  # This creates or assigns an existing menu item to the menu
  def create
    # Try to find existing menu item by name or create new one
    @menu_item = MenuItem.find_or_initialize_by(name: menu_item_params[:name])

    # Update price if provided and item is new or being updated
    if @menu_item.new_record? || menu_item_params[:price_in_cents].present?
      @menu_item.price_in_cents = menu_item_params[:price_in_cents] if menu_item_params[:price_in_cents].present?
    end

    respond_to do |format|
      if @menu_item.save
        # Create the menu assignment if it doesn't exist
        menu_assignment = MenuAssignment.find_or_create_by(menu: @menu, menu_item: @menu_item)

        if menu_assignment.persisted?
          format.html { redirect_to restaurant_menu_menu_item_path(@restaurant, @menu, @menu_item), notice: "Menu item was successfully added." }
          format.json { render :show, status: :created, location: restaurant_menu_menu_item_path(@restaurant, @menu, @menu_item) }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: menu_assignment.errors, status: :unprocessable_entity }
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menu_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /restaurants/:restaurant_id/menus/:menu_id/menu_items/1 or /restaurants/:restaurant_id/menus/:menu_id/menu_items/1.json
  # This removes the menu item from the menu (but doesn't delete the menu item itself)
  def destroy
    menu_assignment = MenuAssignment.find_by(menu: @menu, menu_item: @menu_item)

    if menu_assignment&.destroy
      respond_to do |format|
        format.html { redirect_to restaurant_menu_menu_items_path(@restaurant, @menu), notice: "Menu item was successfully removed from menu.", status: :see_other }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to restaurant_menu_menu_items_path(@restaurant, @menu), alert: "Menu item was not removed.", status: :unprocessable_entity }
        format.json { render json: { error: "Could not remove menu item" }, status: :unprocessable_entity }
      end
    end
  end

  private
    # Set the parent restaurant
    def set_restaurant
      @restaurant = Restaurant.find_by(id: params.expect(:restaurant_id))

      if @restaurant.blank?
        respond_to do |format|
          format.html { redirect_to restaurants_path, alert: "Restaurant not found.", status: :not_found }
          format.json { render json: { error: "Restaurant not found" }, status: :not_found }
        end
      end
    end

    # Set the parent menu
    def set_menu
      @menu = @restaurant.menus.find_by(id: params.expect(:menu_id))

      if @menu.blank?
        respond_to do |format|
          format.html { redirect_to restaurant_menus_path(@restaurant), alert: "Menu not found.", status: :not_found }
          format.json { render json: { error: "Menu not found" }, status: :not_found }
        end
      end
    end

    def set_menu_item
      @menu_item = @menu.menu_items.find_by(id: params.expect(:id))

      if @menu_item.blank?
        respond_to do |format|
          format.html { redirect_to restaurant_menu_menu_items_path(@restaurant, @menu), alert: "Menu item not found.", status: :not_found }
          format.json { render json: { error: "Menu item not found" }, status: :not_found }
        end
      end
    end

    def menu_item_params
      params.expect(menu_item: [ :name, :price_in_cents ])
    end
end
