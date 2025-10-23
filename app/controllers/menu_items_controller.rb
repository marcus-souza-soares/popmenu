class MenuItemsController < ApplicationController
  before_action :set_restaurant
  before_action :set_menu
  before_action :set_menu_item, only: %i[ show destroy ]

  def index
    @menu_items = @menu.menu_items
  end

  def show
  end

  def new
    @menu_item = MenuItem.new
  end

  def edit; end

  def create
    @menu_item = MenuItem.find_or_initialize_by(name: menu_item_params[:name])

    if @menu_item.new_record? || menu_item_params[:price_in_cents].present?
      @menu_item.price_in_cents = menu_item_params[:price_in_cents] if menu_item_params[:price_in_cents].present?
    end

    respond_to do |format|
      if @menu_item.save
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
    def set_restaurant
      super(id: params[:restaurant_id])
    end

    def set_menu
      super(id: params[:menu_id])
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
