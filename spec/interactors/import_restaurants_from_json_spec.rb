require "rails_helper"

RSpec.describe ImportRestaurantsFromJson do
  describe ".call" do
    let(:result) { described_class.call(json_content:) }
    let(:json_content) { nil }

    context "with valid JSON content" do
      let(:json_content) do
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

      it "successfully executes all interactors" do
        expect(result).to be_success
        expect(result.message).to eq("Import completed successfully")
      end

      it "creates records in the database" do
        expect {
          result
        }.to change(Restaurant, :count).by(1)
         .and change(Menu, :count).by(1)
         .and change(MenuItem, :count).by(1)
      end

      it "provides comprehensive results" do
        expect(result.adapted_data).to be_present
        expect(result.import_results).to be_present
        expect(result.logs).to be_present
        expect(result.total_restaurants).to eq(1)
        expect(result.total_menus).to eq(1)
        expect(result.total_menu_items).to eq(1)
      end
    end

    context "with invalid JSON" do
      let(:invalid_json) { "{ invalid }" }
      let(:json_content) { invalid_json }

      it "fails at the parsing stage" do
        expect(result).to be_failure
        expect(result.message).to include("Invalid JSON format")
      end

      it "does not create any records" do
        expect {
          result
        }.not_to change(Restaurant, :count)
      end
    end

    context "with invalid data structure" do
      let(:json_content) do
        {
          "restaurants" => [
            {
              "name" => "",
              "menus" => []
            }
          ]
        }.to_json
      end

      it "fails at the validation stage" do
        expect(result).to be_failure
        expect(result.message).to include("Validation failed")
      end

      it "provides validation errors" do
        expect(result.validation_errors).to be_present
      end
    end

    context "with mixed success and failure" do
      let(:json_content) do
        {
          "restaurants" => [
            {
              "name" => "Valid Restaurant",
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

      it "continues processing all restaurants" do
        expect(result).to be_success
        expect(result.import_results.size).to eq(1)
      end
    end

    context "with comprehensive logging" do
      let(:json_content) do
        {
          "restaurants" => [
            {
              "name" => "Test Restaurant",
              "menus" => [
                {
                  "name" => "lunch",
                  "menu_items" => [
                    { "name" => "Item 1", "price" => 5.00 }
                  ]
                }
              ]
            }
          ]
        }.to_json
      end

      it "collects logs from all interactors" do
        expect(result.logs).to be_an(Array)
        expect(result.logs.size).to be > 3

        messages = result.logs.map { |log| log[:message] }
        expect(messages).to include(/parsed JSON/)
        expect(messages).to include(/validation/)
        expect(messages).to include(/Import completed/)
      end
    end

    context "integration with real-world data" do
      let(:json_content) do
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
                    { "name" => "Burger", "price" => 15.00 },
                    { "name" => "Large Salad", "price" => 8.00 }
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

      it "handles complex multi-restaurant import" do
        expect(result).to be_success
        expect(result.total_restaurants).to eq(2)
        expect(result.total_menus).to eq(3)

        # Burger appears in 2 menus but should be created only once
        expect(MenuItem.where(name: "Burger").count).to eq(1)
      end
    end
  end
end
