require "rails_helper"

RSpec.describe ImportsController, type: :controller do
  let(:action) { -> { post :create, params: { file: file } } }
  let(:json_response) { JSON.parse(response.body) }

  describe "POST #create" do
    let(:valid_json_content) do
      {
        "restaurants" => [
          {
            "name" => "Test Restaurant",
            "menus" => [
              {
                "name" => "lunch",
                "menu_items" => [
                  { "name" => "Burger", "price" => 9.00 }
                ]
              }
            ]
          }
        ]
      }.to_json
    end

    context "with file upload" do
      let(:file) { Rack::Test::UploadedFile.new(StringIO.new(valid_json_content), "application/json", original_filename: "restaurant_data.json") }

      it "returns a successful response" do
        action.call

        expect(response).to have_http_status(:created)
      end

      it "creates records in the database" do
        expect {
          action.call
        }.to change(Restaurant, :count).by(1)
      end

      it "returns success JSON with summary" do
        action.call

        expect(json_response["success"]).to be true
        expect(json_response["summary"]).to be_present
        expect(json_response["summary"]["restaurants"]).to eq(1)
        expect(json_response["summary"]["menus"]).to eq(1)
        expect(json_response["summary"]["menu_items"]).to eq(1)
      end

      it "includes detailed import results" do
        action.call

        expect(json_response["results"]).to be_an(Array)
        expect(json_response["results"].size).to eq(1)
        expect(json_response["results"][0]["restaurant_name"]).to eq("Test Restaurant")
      end

      it "includes logs" do
        action.call

        expect(json_response["logs"]).to be_an(Array)
        expect(json_response["logs"]).not_to be_empty
      end
    end

    context "with raw JSON in request body" do
      let(:action) { -> { post :create, body: valid_json_content } }

      before do
        request.headers["Content-Type"] = "application/json"
      end

      it "processes the JSON successfully" do
        action.call

        expect(response).to have_http_status(:created)
      end

      it "creates records" do
        expect {
          action.call
        }.to change(Restaurant, :count).by(1)
      end
    end

    context "with json_content parameter" do
      let(:action) { -> { post :create, params: { json_content: valid_json_content } } }

      it "processes the JSON successfully" do
        action.call

        expect(response).to have_http_status(:created)
      end
    end

    context "with no content provided" do
      let(:action) { -> { post :create } }

      it "returns an error response" do
        action.call

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns appropriate error message" do
        action.call

        expect(json_response["success"]).to be false
        expect(json_response["message"]).to include("No JSON content provided")
      end
    end

    context "with invalid JSON" do
      let(:invalid_json) { "{ invalid json" }
      let(:file) { Rack::Test::UploadedFile.new(StringIO.new(invalid_json), "application/json", original_filename: "invalid.json") }

      it "returns an error response" do
        action.call

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns appropriate error message" do
        action.call

        expect(json_response["success"]).to be false
        expect(json_response["message"]).to include("Invalid JSON format")
      end

      it "includes error logs" do
        action.call

        expect(json_response["logs"]).to be_present
      end
    end

    context "with validation errors" do
      let(:invalid_data) do
        {
          "restaurants" => [
            {
              "name" => "",
              "menus" => []
            }
          ]
        }.to_json
      end
      let(:file) { Rack::Test::UploadedFile.new(StringIO.new(invalid_data), "application/json", original_filename: "invalid_data.json") }

      it "returns validation error response" do
        action.call

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "includes validation errors in response" do
        action.call

        expect(json_response["validation_errors"]).to be_present
      end
    end

    context "with complex valid data" do
      let(:complex_json) do
        {
          "restaurants" => [
            {
              "name" => "Poppo's Cafe",
              "menus" => [
                {
                  "name" => "lunch",
                  "menu_items" => [
                    { "name" => "Burger", "price" => 9.00 },
                    { "name" => "Small Salad", "price" => 5.00 }
                  ]
                },
                {
                  "name" => "dinner",
                  "menu_items" => [
                    { "name" => "Burger", "price" => 15.00 }
                  ]
                }
              ]
            },
            {
              "name" => "Casa del Poppo",
              "menus" => [
                {
                  "name" => "lunch",
                  "dishes" => [
                    { "name" => "Chicken Wings", "price" => 9.00 }
                  ]
                }
              ]
            }
          ]
        }.to_json
      end
      let(:file) { Rack::Test::UploadedFile.new(StringIO.new(complex_json), "application/json", original_filename: "complex.json") }

      it "handles complex import successfully" do
        action.call

        expect(response).to have_http_status(:created)
      end

      it "creates all records" do
        expect {
          action.call
        }.to change(Restaurant, :count).by(2)
         .and change(Menu, :count).by(3)

        expect(MenuItem.where(name: "Burger").count).to eq(1)
      end

      it "returns accurate summary" do
        action.call

        expect(json_response["summary"]["restaurants"]).to eq(2)
        expect(json_response["summary"]["menus"]).to eq(3)
      end

      it "includes results for all restaurants" do
        action.call

        expect(json_response["results"].size).to eq(2)

        restaurant_names = json_response["results"].map { |r| r["restaurant_name"] }
        expect(restaurant_names).to contain_exactly("Poppo's Cafe", "Casa del Poppo")
      end
    end

    context "with special characters" do
      let(:json_with_special_chars) do
        {
          "restaurants" => [
            {
              "name" => "O'Reilly's Pub",
              "menus" => [
                {
                  "name" => "dinner",
                  "menu_items" => [
                    { "name" => 'Mega "Burger"', "price" => 22.00 }
                  ]
                }
              ]
            }
          ]
        }.to_json
      end
      let(:file) { Rack::Test::UploadedFile.new(StringIO.new(json_with_special_chars), "application/json", original_filename: "special_chars.json") }

      it "handles special characters correctly" do
        action.call

        expect(response).to have_http_status(:created)

        restaurant = Restaurant.last
        expect(restaurant.name).to eq("O'Reilly's Pub")

        menu_item = MenuItem.last
        expect(menu_item.name).to eq('Mega "Burger"')
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(ImportRestaurantsFromJson).to receive(:call).and_raise(StandardError.new("Unexpected error"))
      end

      let(:file) { Rack::Test::UploadedFile.new(StringIO.new(valid_json_content), "application/json", original_filename: "data.json") }

      it "returns internal server error" do
        action.call

        expect(response).to have_http_status(:internal_server_error)
      end

      it "includes error message" do
        action.call

        expect(json_response["success"]).to be false
        expect(json_response["error"]).to eq("Unexpected error")
      end
    end
  end
end
