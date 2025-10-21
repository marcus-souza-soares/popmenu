require 'rails_helper'

RSpec.describe MenuItemsController, type: :controller do
  render_views

  let(:menu) { create(:menu) }
  let(:menu_item) { create(:menu_item, menu: menu) }

  let(:valid_attributes) {
    { name: "Test Menu Item", price_in_cents: 1299 }
  }

  let(:invalid_attributes) {
    { name: "", price_in_cents: -1 }
  }
  let(:json_response) { JSON.parse(response.body) }

  describe "GET #index" do
    let(:action) { -> { get :index, params: { menu_id: menu.id }, format: :json } }

    context "JSON response" do
      it "returns a success response" do
        create(:menu_item, menu: menu)
        action.call

        expect(response).to be_successful
      end

      it "returns only menu items for the specific menu" do
        other_menu = create(:menu, name: "Other Menu")
        menu_item_1 = create(:menu_item, menu: menu, name: "Menu Item 1", price_in_cents: 1299)
        menu_item_2 = create(:menu_item, menu: menu, name: "Menu Item 2", price_in_cents: 999)
        other_item = create(:menu_item, menu: other_menu, name: "Other Item", price_in_cents: 1599)

        action.call

        expect(json_response.length).to eq(2)

        expect(json_response.map { |item| item["name"] }).to contain_exactly("Menu Item 1", "Menu Item 2")
        expect(json_response.map { |item| item["name"] }).not_to include("Other Item")
      end

      it "returns correct menu item attributes" do
        menu_item = create(:menu_item, menu: menu, name: "Test Item", price_in_cents: 1499)

        action.call

        first_item = json_response.first

        expect(first_item["name"]).to eq("Test Item")
        expect(first_item["price_in_cents"]).to eq(1499)
      end
    end
  end

  describe "GET #show" do
    let(:action) { -> { get :show, params: { menu_id: menu.id, id: menu_item.id }, format: :json } }

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

      context "when the menu item is from a different menu" do
        let(:other_menu) { create(:menu) }
        let(:menu_item) { create(:menu_item, menu: other_menu) }

        it "returns 404" do
          action.call
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "POST #create" do
    let(:action) { -> { post :create, params: { menu_id: menu.id, menu_item: attributes }, format: :json } }
    let(:attributes) { nil }

    context "with valid params" do
      let(:attributes) { valid_attributes }
      it "creates a new MenuItem" do
        expect {
          action.call
        }.to change(MenuItem, :count).by(1)
      end

      it "creates a menu item associated with the menu" do
        action.call
        expect(MenuItem.last.menu).to eq(menu)
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
        expect(json_response).to have_key("price_in_cents")
      end
    end
  end

  describe "PUT #update" do
    let(:new_attributes) {
      { name: "Updated Menu Item", price_in_cents: 1599 }
    }
    let(:action) { -> { put :update, params: params, format: :json } }
    let(:attributes) { new_attributes }
    let(:params) { { menu_id: menu.id, id: menu_item.id, menu_item: attributes } }

    context "with valid params" do
      it "updates the requested menu_item" do
        action.call
        menu_item.reload
        expect(menu_item.name).to eq("Updated Menu Item")
        expect(menu_item.price_in_cents).to eq(1599)
      end

      it "returns a 200 OK status" do
        action.call
        expect(response).to have_http_status(:ok)
      end

      it "returns the updated menu item as JSON" do
        action.call

        expect(json_response["name"]).to eq("Updated Menu Item")
        expect(json_response["price_in_cents"]).to eq(1599)
      end

      it "does not allow updating menu_id" do
        other_menu = create(:menu)
        original_menu_id = menu_item.menu_id

        put :update, params: params.merge(menu_id: other_menu.id), format: :json

        menu_item.reload
        expect(menu_item.menu_id).to eq(original_menu_id)
      end
    end

    context "with invalid params" do
      let(:attributes) { invalid_attributes }
      it "does not update the menu item" do
        original_name = menu_item.name
        action.call
        menu_item.reload
        expect(menu_item.name).to eq(original_name)
      end

      it "returns a 422 unprocessable entity status" do
        action.call
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns validation errors as JSON" do
        action.call

        expect(json_response).to have_key("name")
        expect(json_response).to have_key("price_in_cents")
      end
    end

    context "scoping" do
      let(:other_menu) { create(:menu) }
      let(:other_menu_item) { create(:menu_item, menu: other_menu) }
      let(:params) { { menu_id: menu.id, id: other_menu_item.id, menu_item: attributes } }

      it "prevents updating menu items from other menus" do
        action.call
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:action) { -> { delete :destroy, params: params, format: :json } }
    let(:params) { { menu_id: menu.id, id: menu_item.id } }

    it "destroys the requested menu_item" do
      menu_item
      expect {
        action.call
      }.to change(MenuItem, :count).by(-1)
    end

    it "returns a 204 no content status" do
      action.call
      expect(response).to have_http_status(:no_content)
    end

    it "returns an empty response body" do
      action.call
      expect(response.body).to be_blank
    end

    context "scoping" do
      let(:other_menu) { create(:menu) }
      let(:other_menu_item) { create(:menu_item, menu: other_menu) }
      let(:params) { { menu_id: menu.id, id: other_menu_item.id } }

      it "prevents deleting menu items from other menus" do
        action.call
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when destruction fails" do
      it "returns a 422 unprocessable entity status" do
        allow_any_instance_of(MenuItem).to receive(:destroy).and_return(false)

        action.call
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
