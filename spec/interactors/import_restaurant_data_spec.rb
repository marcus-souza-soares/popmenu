require "rails_helper"

RSpec.describe ImportRestaurantData do
  describe ".call" do
    let(:result) { described_class.call(adapted_data:) }

    context "with valid data" do
      let(:adapted_data) do
        [
          {
            name: "Test Restaurant",
            menus: [
              {
                name: "lunch",
                menu_items: [
                  { name: "Burger", price_in_cents: 900 },
                  { name: "Salad", price_in_cents: 500 }
                ]
              }
            ]
          }
        ]
      end

      it "successfully imports restaurants" do
        expect(result).to be_success
        expect(result.total_restaurants).to eq(1)
        expect(result.total_menus).to eq(1)
        expect(result.total_menu_items).to eq(2)
        expect(result.total_assignments).to eq(2)
      end

      it "creates restaurant in database" do
        expect { result }.to change(Restaurant, :count).by(1)

        restaurant = Restaurant.last
        expect(restaurant.name).to eq("Test Restaurant")
      end

      it "creates menus in database" do
        expect { result }.to change(Menu, :count).by(1)

        menu = Menu.last
        expect(menu.name).to eq("lunch")
      end

      it "creates menu items in database" do
        expect { result }.to change(MenuItem, :count).by(2)

        items = MenuItem.last(2)
        expect(items.map(&:name)).to contain_exactly("Burger", "Salad")
      end

      it "creates menu assignments" do
        expect { result }.to change(MenuAssignment, :count).by(2)
      end

      it "returns detailed import results" do
        expect(result.import_results).to be_an(Array)
        expect(result.import_results.size).to eq(1)

        restaurant_result = result.import_results.first
        expect(restaurant_result[:restaurant_name]).to eq("Test Restaurant")
        expect(restaurant_result[:status]).to eq(:success)
        expect(restaurant_result[:menus].size).to eq(1)

        menu_result = restaurant_result[:menus].first
        expect(menu_result[:menu_name]).to eq("lunch")
        expect(menu_result[:menu_items].size).to eq(2)
      end
    end

    context "with duplicate restaurant" do
      let!(:existing_restaurant) { create(:restaurant, name: "Existing Restaurant") }
      let(:adapted_data) do
        [
          {
            name: "Existing Restaurant",
            menus: [
              {
                name: "new_menu",
                menu_items: [
                  { name: "New Item", price_in_cents: 1000 }
                ]
              }
            ]
          }
        ]
      end

      it "reuses existing restaurant" do
        expect { result }.not_to change(Restaurant, :count)

        expect(existing_restaurant.reload.menus.count).to eq(1)
      end

      it "adds new menu to existing restaurant" do
        expect { result }.to change(Menu, :count).by(1)

        new_menu = existing_restaurant.reload.menus.first
        expect(new_menu.name).to eq("new_menu")
      end
    end

    context "with duplicate menu items across menus" do
      let(:adapted_data) do
        [
          {
            name: "Test Restaurant",
            menus: [
              {
                name: "lunch",
                menu_items: [
                  { name: "Burger", price_in_cents: 900 }
                ]
              },
              {
                name: "dinner",
                menu_items: [
                  { name: "Burger", price_in_cents: 1500 }
                ]
              }
            ]
          }
        ]
      end

      it "reuses the same menu item" do
        expect { result }.to change(MenuItem, :count).by(1)
      end

      it "updates the price of the reused item" do
        result
        menu_item = MenuItem.find_by(name: "Burger")
        expect(menu_item.price_in_cents).to eq(1500)
      end

      it "creates multiple assignments for the same item" do
        expect { result }.to change(MenuAssignment, :count).by(2)
      end

      it "marks items appropriately in results" do
        lunch_items = result.import_results[0][:menus][0][:menu_items]
        dinner_items = result.import_results[0][:menus][1][:menu_items]

        expect(lunch_items[0][:action]).to eq(:created)
        expect(dinner_items[0][:action]).to eq(:updated)
      end
    end

    context "with multiple restaurants" do
      let(:adapted_data) do
        [
          {
            name: "Restaurant 1",
            menus: [
              {
                name: "lunch",
                menu_items: [
                  { name: "Item 1", price_in_cents: 500 }
                ]
              }
            ]
          },
          {
            name: "Restaurant 2",
            menus: [
              {
                name: "lunch",
                menu_items: [
                  { name: "Item 2", price_in_cents: 600 }
                ]
              }
            ]
          }
        ]
      end

      it "imports all restaurants" do
        expect { result }.to change(Restaurant, :count).by(2)
      end

      it "returns results for all restaurants" do
        expect(result.import_results.size).to eq(2)
        expect(result.import_results[0][:restaurant_name]).to eq("Restaurant 1")
        expect(result.import_results[1][:restaurant_name]).to eq("Restaurant 2")
      end
    end

    context "with invalid data" do
      let(:adapted_data) do
        [
          {
            name: "",
            menus: [
              {
                name: "lunch",
                menu_items: [
                  { name: "Burger", price_in_cents: 900 }
                ]
              }
            ]
          }
        ]
      end

      it "handles validation errors gracefully" do
        result = described_class.call(adapted_data: adapted_data)

        expect(result).to be_success
        restaurant_result = result.import_results.first
        expect(restaurant_result[:status]).to eq(:failed)
        expect(restaurant_result[:errors]).to be_present
      end

      it "does not create invalid records" do
        expect { result }.not_to change(Restaurant, :count)
      end
    end

    context "with special characters" do
      let(:adapted_data) do
        [
          {
            name: "O'Reilly's Restaurant",
            menus: [
              {
                name: "dinner",
                menu_items: [
                  { name: 'Mega "Burger"', price_in_cents: 2200 }
                ]
              }
            ]
          }
        ]
      end

      it "handles special characters correctly" do
        expect(result).to be_success

        restaurant = Restaurant.last
        expect(restaurant.name).to eq("O'Reilly's Restaurant")

        menu_item = MenuItem.last
        expect(menu_item.name).to eq('Mega "Burger"')
      end
    end

    context "with logs" do
      let(:adapted_data) do
        [
          {
            name: "Test Restaurant",
            menus: [
              {
                name: "lunch",
                menu_items: [
                  { name: "Burger", price_in_cents: 900 }
                ]
              }
            ]
          }
        ]
      end

      it "generates appropriate logs" do
        expect(result.logs).to be_present
        expect(result.logs).to include(
          hash_including(level: :info, message: /Starting import/)
        )
        expect(result.logs).to include(
          hash_including(level: :info, message: /Import completed/)
        )
      end
    end
  end
end
