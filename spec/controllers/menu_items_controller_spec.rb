require 'rails_helper'

RSpec.describe MenuItemsController, type: :controller do
  render_views

  let(:restaurant) { create(:restaurant) }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:menu_item) { create(:menu_item) }

  let(:valid_attributes) {
    { name: "Test Menu Item", price_in_cents: 1299 }
  }

  let(:invalid_attributes) {
    { name: "", price_in_cents: -1 }
  }

  let(:json_response) { JSON.parse(response.body) }

  describe "GET #index" do
    let(:action) { -> { get :index, params: { restaurant_id: restaurant.id, menu_id: menu.id }, format: :json } }

    context "JSON response" do
      it "returns a success response" do
        menu_item = create(:menu_item)
        MenuAssignment.create!(menu: menu, menu_item: menu_item)
        action.call

        expect(response).to be_successful
      end

      it "returns only menu items for the specific menu" do
        other_menu = create(:menu, restaurant: restaurant)
        menu_item1 = create(:menu_item, name: "Item 1")
        menu_item2 = create(:menu_item, name: "Item 2")
        other_item = create(:menu_item, name: "Other Item")

        MenuAssignment.create!(menu: menu, menu_item: menu_item1)
        MenuAssignment.create!(menu: menu, menu_item: menu_item2)
        MenuAssignment.create!(menu: other_menu, menu_item: other_item)

        action.call

        expect(json_response.length).to eq(2)
        expect(json_response.map { |item| item["name"] }).to contain_exactly("Item 1", "Item 2")
      end

      it "returns correct menu item attributes" do
        menu_item = create(:menu_item, name: "Test Item", price_in_cents: 1499)
        MenuAssignment.create!(menu: menu, menu_item: menu_item)

        action.call

        first_item = json_response.first
        expect(first_item["name"]).to eq("Test Item")
        expect(first_item["price_in_cents"]).to eq(1499)
      end
    end
  end

  describe "GET #show" do
    let(:action) { -> { get :show, params: params, format: :json } }
    let(:params) { { restaurant_id: restaurant.id, menu_id: menu.id, id: menu_item.id } }

    before do
      MenuAssignment.create!(menu: menu, menu_item: menu_item)
    end

    context "JSON response" do
      it "returns a success response" do
        action.call

        expect(response).to be_successful
      end

      it "returns the correct menu item" do
        action.call

        expect(json_response["id"]).to eq(menu_item.id)
        expect(json_response["name"]).to eq(menu_item.name)
        expect(json_response["price_in_cents"]).to eq(menu_item.price_in_cents)
      end

      context "when the menu item is not on this menu" do
        let(:other_menu_item) { create(:menu_item) }
        let(:params) { { restaurant_id: restaurant.id, menu_id: menu.id, id: other_menu_item.id } }

        it "returns 404" do
          action.call
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "POST #create" do
    let(:action) { -> { post :create, params: { restaurant_id: restaurant.id, menu_id: menu.id, menu_item: attributes }, format: :json } }
    let(:attributes) { nil }

    context "with valid params for new menu item" do
      let(:attributes) { valid_attributes }

      it "creates a new MenuItem" do
        expect {
          action.call
        }.to change(MenuItem, :count).by(1)
      end

      it "creates a MenuAssignment" do
        expect {
          action.call
        }.to change(MenuAssignment, :count).by(1)
      end

      it "associates the menu item with the menu" do
        action.call
        expect(Menu.find(menu.id).menu_items.last.name).to eq("Test Menu Item")
      end

      it "returns a 201 created status" do
        action.call
        expect(response).to have_http_status(:created)
      end

      it "returns the created menu item as JSON" do
        action.call

        expect(json_response["name"]).to eq("Test Menu Item")
        expect(json_response["price_in_cents"]).to eq(1299)
      end
    end

    context "with existing menu item name (reuse)" do
      let!(:existing_item) { create(:menu_item, name: "Existing Item", price_in_cents: 999) }
      let(:attributes) { { name: "Existing Item", price_in_cents: 1299 } }

      it "does not create a new MenuItem" do
        expect {
          action.call
        }.not_to change(MenuItem, :count)
      end

      it "creates a MenuAssignment for existing item" do
        expect {
          action.call
        }.to change(MenuAssignment, :count).by(1)
      end

      it "adds the existing item to the menu" do
        action.call
        expect(menu.reload.menu_items).to include(existing_item)
      end

      it "updates the price if provided" do
        action.call
        existing_item.reload
        expect(existing_item.price_in_cents).to eq(1299)
      end
    end

    context "with invalid params" do
      let(:attributes) { invalid_attributes }

      it "does not create a menu item" do
        expect {
          action.call
        }.not_to change(MenuItem, :count)
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

    context "when menu item already on menu" do
      let!(:existing_item) { create(:menu_item, name: "Existing Item") }
      let(:attributes) { { name: "Existing Item" } }

      before do
        MenuAssignment.create!(menu: menu, menu_item: existing_item)
      end

      it "does not create duplicate assignment" do
        expect {
          action.call
        }.not_to change(MenuAssignment, :count)
      end

      it "returns success (idempotent)" do
        action.call
        expect(response).to have_http_status(:created)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:action) { -> { delete :destroy, params: params, format: :json } }
    let(:params) { { restaurant_id: restaurant.id, menu_id: menu.id, id: menu_item.id } }

    before do
      MenuAssignment.create!(menu: menu, menu_item: menu_item)
    end

    it "removes the menu item from the menu" do
      expect {
        action.call
      }.to change(MenuAssignment, :count).by(-1)
    end

    it "does NOT delete the menu item itself" do
      expect {
        action.call
      }.not_to change(MenuItem, :count)
    end

    it "returns a 204 no content status" do
      action.call
      expect(response).to have_http_status(:no_content)
    end

    it "returns an empty response body" do
      action.call
      expect(response.body).to be_blank
    end

    context "when menu item is on multiple menus" do
      let(:other_menu) { create(:menu, restaurant: restaurant) }

      before do
        MenuAssignment.create!(menu: other_menu, menu_item: menu_item)
      end

      it "only removes from the specified menu" do
        action.call

        expect(menu.reload.menu_items).not_to include(menu_item)
        expect(other_menu.reload.menu_items).to include(menu_item)
      end
    end

    context "scoping" do
      let(:other_restaurant) { create(:restaurant) }
      let(:other_menu) { create(:menu, restaurant: other_restaurant) }
      let(:params) { { restaurant_id: restaurant.id, menu_id: other_menu.id, id: menu_item.id } }

      before do
        MenuAssignment.create!(menu: other_menu, menu_item: menu_item)
        action.call
      end

      it "prevents removing menu items from other restaurant's menus" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "menu item uniqueness across restaurant" do
    it "allows the same menu item on multiple menus within a restaurant" do
      menu2 = create(:menu, restaurant: restaurant)
      menu_item = create(:menu_item, name: "Shared Item")

      MenuAssignment.create!(menu: menu, menu_item: menu_item)
      MenuAssignment.create!(menu: menu2, menu_item: menu_item)

      expect(menu.menu_items).to include(menu_item)
      expect(menu2.menu_items).to include(menu_item)
    end
  end
end
