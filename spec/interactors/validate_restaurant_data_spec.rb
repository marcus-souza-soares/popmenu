require "rails_helper"

RSpec.describe ValidateRestaurantData do
  describe ".call" do
    let(:result) { described_class.call(adapted_data: adapted_data) }
    let(:price_in_cents) { 9_00 }
    let(:menu_item_name) { "Burger" }
    let(:adapted_data) do
      [
        {
          name: "Test Restaurant",
          menus: [
            {
              name: "lunch",
              menu_items: [
                { name: menu_item_name, price_in_cents: }
              ]
            }
          ]
        }
      ]
    end

    context "with valid data" do

      it "successfully validates the data" do
        expect(result).to be_success
        expect(result.validation_errors).to eq([])
      end

      it "logs validation completion" do
        expect(result.logs).to include(
          hash_including(level: :info, message: "Data validation completed successfully")
        )
      end
    end

    context "with invalid data structure" do
      context "when adapted_data is not an array" do
        let(:adapted_data) { "not an array" }

        it "fails with an error message" do
          expect(result).to be_failure
          expect(result.message).to include("Invalid data structure")
        end
      end

      context "when adapted_data is empty" do
        let(:adapted_data) { [] }

        it "fails with an error message" do
          expect(result).to be_failure
          expect(result.message).to eq("No restaurants found in data")
        end
      end
    end

    context "with missing restaurant fields" do
      let(:adapted_data) do
        [
          {
            name: nil,
            menus: []
          }
        ]
      end

      it "fails validation" do
        expect(result).to be_failure
        expect(result.validation_errors).to include(
          hash_including(path: "restaurants[0]", message: "name is required")
        )
      end
    end

    context "with missing menu fields" do
      let(:adapted_data) do
        [
          {
            name: "Test Restaurant",
            menus: [
              { name: nil, menu_items: [] }
            ]
          }
        ]
      end

      it "fails validation" do
        expect(result).to be_failure
        expect(result.validation_errors).to include(
          hash_including(
            path: "restaurants[0].menus[0]",
            message: "name is required"
          )
        )
      end
    end

    context "with missing menu item fields" do
      let(:menu_item_name) { nil }

      it "fails validation with name error" do
        expect(result).to be_failure
        expect(result.validation_errors).to include(
          hash_including(
            path: "restaurants[0].menus[0].menu_items[0]",
            message: "name is required"
          )
        )
      end
    end

    context "with invalid menu item price" do
      shared_examples "fails with a price error" do |message|
        it "fails with an error message" do
          expect(result).to be_failure
          expect(result.validation_errors).to include(
            hash_including(message:)
          )
        end
      end

      let(:price_in_cents) { nil }

      context "when price is missing" do
        it_behaves_like "fails with a price error", "price is required"
      end

      context "when price is zero" do
        let(:price_in_cents) { 0 }

        it_behaves_like "fails with a price error", "price must be greater than 0"
      end

      context "when price is negative" do
        let(:price_in_cents) { -100 }

        it_behaves_like "fails with a price error", "price must be greater than 0"
      end
    end

    context "with empty collections" do
      let(:adapted_data) do
        [
          {
            name: "Test Restaurant",
            menus: []
          }
        ]
      end

      it "adds a warning for empty menus" do
        expect(result).to be_failure
        expect(result.validation_errors).to include(
          hash_including(
            path: "restaurants[0]",
            message: "has no menus",
            severity: :warning
          )
        )
      end
    end

    context "with multiple validation errors" do
      let(:adapted_data) do
        [
          {
            name: nil,
            menus: [
              {
                name: nil,
                menu_items: [
                  { name: nil, price_in_cents: -100 }
                ]
              }
            ]
          }
        ]
      end

      it "collects all errors" do
        expect(result).to be_failure
        expect(result.validation_errors.size).to be >= 3
      end
    end
  end
end
