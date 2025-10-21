require 'rails_helper'

RSpec.describe MenusController, type: :controller do
  render_views

  let(:valid_attributes) {
    { name: "Test Menu" }
  }

  let(:invalid_attributes) {
    { name: "" }
  }

  let(:json_response) { JSON.parse(response.body) }

  describe "GET #index" do
    let(:action) { -> { get :index, format: :json } }

    context "JSON response" do
      it "returns a success response" do
        create(:menu)
        action.call

        expect(response).to be_successful
      end

      it "returns all menus" do
        menu1 = create(:menu, name: "Lunch Menu")
        menu2 = create(:menu, name: "Dinner Menu")

        action.call

        expect(json_response.length).to eq(2)
        expect(json_response.map { |m| m["name"] }).to contain_exactly("Lunch Menu", "Dinner Menu")
      end

      it "returns correct menu attributes" do
        menu = create(:menu, name: "Breakfast Menu")

        action.call

        first_menu = json_response.first
        expect(first_menu["name"]).to eq("Breakfast Menu")
        expect(first_menu["id"]).to eq(menu.id)
      end
    end
  end

  describe "GET #show" do
    let(:menu) { create(:menu) }
    let(:action) { -> { get :show, params: { id: menu.id }, format: :json } }

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

      it "returns 404 for non-existent menu" do
        get :show, params: { id: Float::INFINITY }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #create" do
    let(:action) { -> { post :create, params: { menu: attributes }, format: :json } }
    let(:attributes) { nil }

    context "with valid params" do
      let(:attributes) { valid_attributes }

      it "creates a new Menu" do
        expect {
          action.call
        }.to change(Menu, :count).by(1)
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

      it "creates a menu with the correct attributes" do
        action.call

        created_menu = Menu.last
        expect(created_menu.name).to eq("Test Menu")
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
    let(:menu) { create(:menu, name: "Original Name") }
    let(:new_attributes) {
      { name: "Updated Menu Name" }
    }
    let(:action) { -> { put :update, params: params, format: :json } }
    let(:attributes) { new_attributes }
    let(:params) { { id: menu.id, menu: attributes } }

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

    context "non-existent menu" do
      let(:params) { { id: Float::INFINITY, menu: attributes } }

      it "returns 404" do
        action.call
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:menu) { create(:menu) }
    let(:action) { -> { delete :destroy, params: params, format: :json } }
    let(:params) { { id: menu.id } }

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
      it "destroys the menu and its associated menu items" do
        create(:menu_item, menu: menu)
        create(:menu_item, name: "Other Menu Item", menu: menu)

        expect {
          action.call
        }.to change(Menu, :count).by(-1)
         .and change(MenuItem, :count).by(-2)
      end
    end

    context "when destruction fails" do
      it "returns a 422 unprocessable entity status" do
        allow_any_instance_of(Menu).to receive(:destroy).and_return(false)

        action.call
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "non-existent menu" do
      let(:params) { { id: Float::INFINITY } }

      it "returns 404" do
        action.call
        expect(response).to have_http_status(:not_found)
      end
    end
  end

end
