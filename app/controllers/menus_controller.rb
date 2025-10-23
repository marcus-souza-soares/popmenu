class MenusController < ApplicationController
  before_action :set_restaurant
  before_action :set_menu, only: %i[ show edit update destroy ]

  def index
    @menus = @restaurant.menus
  end

  def show
  end

  def new
    @menu = @restaurant.menus.build
  end

  def edit
  end

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
    def set_restaurant
      super(id: params[:restaurant_id])
    end

    def set_menu
      super(id: params[:id])
    end

    def menu_params
      params.expect(menu: [ :name ])
    end
end
