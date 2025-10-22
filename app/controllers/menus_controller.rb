class MenusController < ApplicationController
  before_action :set_restaurant
  before_action :set_menu, only: %i[ show edit update destroy ]

  # GET /restaurants/:restaurant_id/menus or /restaurants/:restaurant_id/menus.json
  def index
    @menus = @restaurant.menus
  end

  # GET /restaurants/:restaurant_id/menus/1 or /restaurants/:restaurant_id/menus/1.json
  def show
  end

  # GET /restaurants/:restaurant_id/menus/new
  def new
    @menu = @restaurant.menus.build
  end

  # GET /restaurants/:restaurant_id/menus/1/edit
  def edit
  end

  # POST /restaurants/:restaurant_id/menus or /restaurants/:restaurant_id/menus.json
  def create
    @menu = @restaurant.menus.build(menu_params)

    respond_to do |format|
      if @menu.save
        format.html { redirect_to restaurant_menu_path(@restaurant, @menu), notice: "Menu was successfully created." }
        format.json { render :show, status: :created, location: restaurant_menu_path(@restaurant, @menu) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /restaurants/:restaurant_id/menus/1 or /restaurants/:restaurant_id/menus/1.json
  def update
    respond_to do |format|
      if @menu.update(menu_params)
        format.html { redirect_to restaurant_menu_path(@restaurant, @menu), notice: "Menu was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: restaurant_menu_path(@restaurant, @menu) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /restaurants/:restaurant_id/menus/1 or /restaurants/:restaurant_id/menus/1.json
  def destroy
    if @menu.destroy
      respond_to do |format|
        format.html { redirect_to restaurant_menus_path(@restaurant), notice: "Menu was successfully destroyed.", status: :see_other }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to restaurant_menus_path(@restaurant), alert: "Menu was not destroyed.", status: :unprocessable_entity }
        format.json { render json: @menu.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Set the parent restaurant
    def set_restaurant
      super(id: params[:restaurant_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_menu
      super(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def menu_params
      params.expect(menu: [ :name ])
    end
end
