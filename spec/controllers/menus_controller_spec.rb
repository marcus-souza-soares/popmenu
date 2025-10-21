require 'rails_helper'

RSpec.describe MenusController, type: :controller do
  render_views

  let(:restaurant) { create(:restaurant) }
  let(:menu) { create(:menu, restaurant: restaurant) }

  let(:valid_attributes) {
    { name: "Test Menu" }
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  let(:json_response) { JSON.parse(response.body) }

  describe "GET #index" do
    let(:action) { -> { get :index, params: { restaurant_id: restaurant.id }, format: :json } }

    context "JSON response" do
      it "returns a success response" do
        create(:menu, restaurant: restaurant)
        action.call

        expect(response).to be_successful
      end

      it "returns only menus for the specific restaurant" do
        other_restaurant = create(:restaurant)
        menu1 = create(:menu, restaurant: restaurant, name: "Menu 1")
        menu2 = create(:menu, restaurant: restaurant, name: "Menu 2")
        other_menu = create(:menu, restaurant: other_restaurant, name: "Other Menu")

        action.call

        expect(json_response.length).to eq(2)
        expect(json_response.map { |m| m["name"] }).to contain_exactly("Menu 1", "Menu 2")
      end

      it "includes menu items in menu data" do
        menu = create(:menu, restaurant: restaurant)
        menu_item1 = create(:menu_item, name: "Item 1", price_in_cents: 1299)
        menu_item2 = create(:menu_item, name: "Item 2", price_in_cents: 999)
        MenuAssignment.create!(menu: menu, menu_item: menu_item1)
        MenuAssignment.create!(menu: menu, menu_item: menu_item2)

        action.call

        first_menu = json_response.first
        expect(first_menu["menu_items"].length).to eq(2)
        expect(first_menu["menu_items"].map { |mi| mi["name"] }).to contain_exactly("Item 1", "Item 2")
      end
    end
  end

  describe "GET #show" do
    let(:action) { -> { get :show, params: { restaurant_id: restaurant.id, id: menu.id }, format: :json } }

    context "JSON response" do
      it "returns a success response" do
        action.call

        expect(response).to be_successful
      end

      it "returns the correct menu" do
        action.call

        expect(json_response["id"]).to eq(menu.id)
        expect(json_response["name"]).to eq(menu.name)
      end

      it "includes menu items in the response" do
        menu_item = create(:menu_item, name: "Special Item", price_in_cents: 1599)
        MenuAssignment.create!(menu: menu, menu_item: menu_item)

        action.call

        expect(json_response["menu_items"]).to be_present
        expect(json_response["menu_items"].first["name"]).to eq("Special Item")
      end

      context "when the menu belongs to a different restaurant" do
        let(:other_restaurant) { create(:restaurant) }
        let(:menu) { create(:menu, restaurant: other_restaurant) }

        it "returns 404" do
          action.call
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "POST #create" do
    let(:action) { -> { post :create, params: { restaurant_id: restaurant.id, menu: attributes }, format: :json } }
    let(:attributes) { nil }

    context "with valid params" do
      let(:attributes) { valid_attributes }

      it "creates a new Menu" do
        expect {
          action.call
        }.to change(Menu, :count).by(1)
      end

      it "creates a menu associated with the restaurant" do
        action.call
        expect(Menu.last.restaurant).to eq(restaurant)
      end

      it "returns a 201 created status" do
        action.call
        expect(response).to have_http_status(:created)
      end

      it "returns the created menu as JSON" do
        action.call

        expect(json_response["name"]).to eq("Test Menu")
        expect(json_response["id"]).to be_present
      end
    end

    context "with invalid params" do
      let(:attributes) { invalid_attributes }

      it "does not create a menu" do
        expect {
          action.call
        }.not_to change(Menu, :count)
      end

      it "returns a 422 unprocessable entity status" do
        action.call
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns validation errors as JSON" do
        action.call

        expect(json_response).to have_key("name")
      end
    end
  end

  describe "PUT #update" do
    let(:new_attributes) {
      { name: "Updated Menu Name" }
    }
    let(:action) { -> { put :update, params: params, format: :json } }
    let(:attributes) { new_attributes }
    let(:params) { { restaurant_id: restaurant.id, id: menu.id, menu: attributes } }

    context "with valid params" do
      it "updates the requested menu" do
        action.call
        menu.reload
        expect(menu.name).to eq("Updated Menu Name")
      end

      it "returns a 200 OK status" do
        action.call
        expect(response).to have_http_status(:ok)
      end

      it "returns the updated menu as JSON" do
        action.call

        expect(json_response["name"]).to eq("Updated Menu Name")
        expect(json_response["id"]).to eq(menu.id)
      end
    end

    context "with invalid params" do
      let(:attributes) { invalid_attributes }

      it "does not update the menu" do
        original_name = menu.name
        action.call
        menu.reload
        expect(menu.name).to eq(original_name)
      end

      it "returns a 422 unprocessable entity status" do
        action.call
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns validation errors as JSON" do
        action.call

        expect(json_response).to have_key("name")
      end
    end

    context "scoping" do
      let(:other_restaurant) { create(:restaurant) }
      let(:menu) { create(:menu, restaurant: other_restaurant) }

      it "prevents updating menus from other restaurants" do
        action.call
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:action) { -> { delete :destroy, params: params, format: :json } }
    let(:params) { { restaurant_id: restaurant.id, id: menu.id } }

    it "destroys the requested menu" do
      menu
      expect {
        action.call
      }.to change(Menu, :count).by(-1)
    end

    it "returns a 204 no content status" do
      action.call
      expect(response).to have_http_status(:no_content)
    end

    it "returns an empty response body" do
      action.call
      expect(response.body).to be_blank
    end

    context "when menu has menu items" do
      it "destroys the menu and menu assignments but keeps menu items" do
        menu_item = create(:menu_item)
        MenuAssignment.create!(menu: menu, menu_item: menu_item)

        expect {
          action.call
        }.to change(Menu, :count).by(-1)
         .and change(MenuAssignment, :count).by(-1)
         .and change(MenuItem, :count).by(0) # Menu items are preserved
      end
    end

    context "scoping" do
      let(:other_restaurant) { create(:restaurant) }
      let(:menu) { create(:menu, restaurant: other_restaurant) }

      it "prevents deleting menus from other restaurants" do
        action.call
        expect(response).to have_http_status(:not_found)
      end
    end
  end

end
