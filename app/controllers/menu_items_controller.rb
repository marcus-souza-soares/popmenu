class MenuItemsController < ApplicationController
  before_action :set_menu
  before_action :set_menu_item, only: %i[ show edit update destroy ]

  # GET /menus/:menu_id/menu_items or /menus/:menu_id/menu_items.json
  def index
    @menu_items = @menu.menu_items
  end

  # GET /menus/:menu_id/menu_items/1 or /menus/:menu_id/menu_items/1.json
  def show
    if @menu_item.present?
      render :show
    else
      render json: { error: "Menu item not found" }, status: :not_found
    end
  end

  # GET /menus/:menu_id/menu_items/new
  def new
    @menu_item = @menu.menu_items.build
  end

  # GET /menus/:menu_id/menu_items/1/edit
  def edit
  end

  # POST /menus/:menu_id/menu_items or /menus/:menu_id/menu_items.json
  def create
    @menu_item = @menu.menu_items.build(menu_item_params)

    respond_to do |format|
      if @menu_item.save
        format.html { redirect_to menu_menu_item_path(@menu, @menu_item), notice: "Menu item was successfully created." }
        format.json { render :show, status: :created, location: menu_menu_item_path(@menu, @menu_item) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menu_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /menus/:menu_id/menu_items/1 or /menus/:menu_id/menu_items/1.json
  def update
    respond_to do |format|
      if @menu_item.update(menu_item_params)
        format.html { redirect_to menu_menu_item_path(@menu, @menu_item), notice: "Menu item was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: menu_menu_item_path(@menu, @menu_item) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menu_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /menus/:menu_id/menu_items/1 or /menus/:menu_id/menu_items/1.json
  def destroy
    if @menu_item.destroy
      respond_to do |format|
        format.html { redirect_to menu_menu_items_path(@menu), notice: "Menu item was successfully destroyed.", status: :see_other }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to menu_menu_items_path(@menu), alert: "Menu item was not destroyed.", status: :unprocessable_entity }
        format.json { render json: @menu_item.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_menu
      @menu = Menu.find_by(id: params.expect(:menu_id))

      if @menu.blank?
        if request.format.json?
          render json: { error: "Menu not found" }, status: :not_found
        else
          redirect_to menus_path, alert: "Menu not found", status: :not_found
        end
      end
    end

    def set_menu_item
      @menu_item = @menu.menu_items.find_by(id: params[:id])

      if @menu_item.blank?
        if request.format.json?
          render json: { error: "Menu item not found" }, status: :not_found
        else
          redirect_to menu_menu_items_path(@menu), alert: "Menu item not found", status: :not_found
        end
      end
    end

    def menu_item_params
      params.expect(menu_item: [ :name, :price_in_cents ])
    end
end
