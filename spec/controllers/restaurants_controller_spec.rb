require 'rails_helper'

RSpec.describe RestaurantsController, type: :controller do
  render_views

  let(:valid_attributes) {
    { name: "Test Restaurant" }
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  let(:json_response) { JSON.parse(response.body) }

  describe "GET #index" do
    let(:action) { -> { get :index, format: :json } }

    context "JSON response" do
      it "returns a success response" do
        create(:restaurant)
        action.call

        expect(response).to be_successful
      end

      it "returns all restaurants" do
        restaurant1 = create(:restaurant, name: "Restaurant 1")
        restaurant2 = create(:restaurant, name: "Restaurant 2")

        action.call

        expect(json_response.length).to eq(2)
        expect(json_response.map { |r| r["name"] }).to contain_exactly("Restaurant 1", "Restaurant 2")
      end

      it "includes menus in restaurant data" do
        restaurant = create(:restaurant, name: "Test Restaurant")
        menu1 = create(:menu, restaurant: restaurant, name: "Lunch Menu")
        menu2 = create(:menu, restaurant: restaurant, name: "Dinner Menu")

        action.call

        first_restaurant = json_response.first
        expect(first_restaurant["menus"].length).to eq(2)
        expect(first_restaurant["menus"].map { |m| m["name"] }).to contain_exactly("Lunch Menu", "Dinner Menu")
      end
    end
  end

  describe "GET #show" do
    let(:restaurant) { create(:restaurant) }
    let(:action) { -> { get :show, params: { id: restaurant.id }, format: :json } }

    context "JSON response" do
      it "returns a success response" do
        action.call

        expect(response).to be_successful
      end

      it "returns the correct restaurant" do
        action.call

        expect(json_response["id"]).to eq(restaurant.id)
        expect(json_response["name"]).to eq(restaurant.name)
      end

      it "includes menus in the response" do
        menu = create(:menu, restaurant: restaurant, name: "Breakfast Menu")

        action.call

        expect(json_response["menus"]).to be_present
        expect(json_response["menus"].first["name"]).to eq("Breakfast Menu")
      end

      it "returns 404 for non-existent restaurant" do
        get :show, params: { id: Float::INFINITY }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #create" do
    let(:action) { -> { post :create, params: { restaurant: attributes }, format: :json } }
    let(:attributes) { nil }

    context "with valid params" do
      let(:attributes) { valid_attributes }

      it "creates a new Restaurant" do
        expect {
          action.call
        }.to change(Restaurant, :count).by(1)
      end

      it "returns a 201 created status" do
        action.call
        expect(response).to have_http_status(:created)
      end

      it "returns the created restaurant as JSON" do
        action.call

        expect(json_response["name"]).to eq("Test Restaurant")
        expect(json_response["id"]).to be_present
      end
    end

    context "with invalid params" do
      let(:attributes) { invalid_attributes }

      it "does not create a restaurant" do
        expect {
          action.call
        }.not_to change(Restaurant, :count)
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

    context "with duplicate name" do
      let(:attributes) { { name: "Existing Restaurant" } }

      it "does not create a duplicate restaurant" do
        create(:restaurant, name: "Existing Restaurant")

        expect {
          action.call
        }.not_to change(Restaurant, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PUT #update" do
    let(:restaurant) { create(:restaurant, name: "Original Name") }
    let(:new_attributes) {
      { name: "Updated Restaurant Name" }
    }
    let(:action) { -> { put :update, params: params, format: :json } }
    let(:attributes) { new_attributes }
    let(:params) { { id: restaurant.id, restaurant: attributes } }

    context "with valid params" do
      it "updates the requested restaurant" do
        action.call
        restaurant.reload
        expect(restaurant.name).to eq("Updated Restaurant Name")
      end

      it "returns a 200 OK status" do
        action.call
        expect(response).to have_http_status(:ok)
      end

      it "returns the updated restaurant as JSON" do
        action.call

        expect(json_response["name"]).to eq("Updated Restaurant Name")
        expect(json_response["id"]).to eq(restaurant.id)
      end
    end

    context "with invalid params" do
      let(:attributes) { invalid_attributes }

      it "does not update the restaurant" do
        original_name = restaurant.name
        action.call
        restaurant.reload
        expect(restaurant.name).to eq(original_name)
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

    context "non-existent restaurant" do
      let(:params) { { id: Float::INFINITY, restaurant: attributes } }

      it "returns 404" do
        action.call
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:restaurant) { create(:restaurant) }
    let(:action) { -> { delete :destroy, params: params, format: :json } }
    let(:params) { { id: restaurant.id } }

    it "destroys the requested restaurant" do
      restaurant
      expect {
        action.call
      }.to change(Restaurant, :count).by(-1)
    end

    it "returns a 204 no content status" do
      action.call
      expect(response).to have_http_status(:no_content)
    end

    it "returns an empty response body" do
      action.call
      expect(response.body).to be_blank
    end

    context "when restaurant has menus" do
      it "destroys the restaurant and its associated menus" do
        menu1 = create(:menu, restaurant: restaurant)
        menu2 = create(:menu, restaurant: restaurant)

        expect {
          action.call
        }.to change(Restaurant, :count).by(-1)
         .and change(Menu, :count).by(-2)
      end
    end

    context "when restaurant has menus with menu items" do
      it "destroys everything but keeps menu items (they're shared)" do
        menu = create(:menu, restaurant: restaurant)
        menu_item = create(:menu_item)
        MenuAssignment.create!(menu: menu, menu_item: menu_item)

        expect {
          action.call
        }.to change(Restaurant, :count).by(-1)
         .and change(Menu, :count).by(-1)
         .and change(MenuAssignment, :count).by(-1)
         .and change(MenuItem, :count).by(0) # Menu items are not deleted
      end
    end

    context "non-existent restaurant" do
      let(:params) { { id: Float::INFINITY } }

      it "returns 404" do
        action.call
        expect(response).to have_http_status(:not_found)
      end
    end
  end

end
