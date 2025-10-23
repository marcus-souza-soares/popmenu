require "rails_helper"

RSpec.describe RestaurantJsonAdapter do
  describe "#adapt" do
    let(:adapter) { described_class.new(raw_data) }
    let(:result) { adapter.adapt }

    context "with valid restaurant data" do
      let(:raw_data) do
        {
          "restaurants" => [
            {
              "name" => "Test Restaurant",
              "menus" => [
                {
                  "name" => "lunch",
                  "menu_items" => [
                    { "name" => "Burger", "price" => 9.00 },
                    { "name" => "Salad", "price" => 5.50 }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "adapts the data correctly" do
        expect(result).to be_an(Array)
        expect(result.size).to eq(1)

        restaurant = result.first
        expect(restaurant[:name]).to eq("Test Restaurant")
        expect(restaurant[:menus].size).to eq(1)

        menu = restaurant[:menus].first
        expect(menu[:name]).to eq("lunch")
        expect(menu[:menu_items].size).to eq(2)

        item = menu[:menu_items].first
        expect(item[:name]).to eq("Burger")
        expect(item[:price_in_cents]).to eq(900)
      end

      it "converts prices to cents" do
        menu_items = result.first[:menus].first[:menu_items]

        expect(menu_items[0][:price_in_cents]).to eq(900)
        expect(menu_items[1][:price_in_cents]).to eq(550)
      end
    end

    context "with dishes instead of menu_items" do
      let(:raw_data) do
        {
          "restaurants" => [
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
        }
      end

      it "handles dishes as menu_items" do
        menu = result.first[:menus].first

        expect(menu[:menu_items].size).to eq(1)
        expect(menu[:menu_items].first[:name]).to eq("Chicken Wings")
      end
    end

    context "with special characters in names" do
      let(:raw_data) do
        {
          "restaurants" => [
            {
              "name" => "O'Reilly's",
              "menus" => [
                {
                  "name" => "dinner",
                  "menu_items" => [
                    { "name" => "Mega \"Burger\"", "price" => 22.00 }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "preserves special characters" do
        restaurant = result.first
        expect(restaurant[:name]).to eq("O'Reilly's")

        item = restaurant[:menus].first[:menu_items].first
        expect(item[:name]).to eq("Mega \"Burger\"")
      end
    end

    context "with multiple restaurants" do
      let(:raw_data) do
        {
          "restaurants" => [
            {
              "name" => "Restaurant 1",
              "menus" => [
                { "name" => "lunch", "menu_items" => [] }
              ]
            },
            {
              "name" => "Restaurant 2",
              "menus" => [
                { "name" => "dinner", "menu_items" => [] }
              ]
            }
          ]
        }
      end

      it "adapts all restaurants" do
        expect(result.size).to eq(2)
        expect(result[0][:name]).to eq("Restaurant 1")
        expect(result[1][:name]).to eq("Restaurant 2")
      end
    end

    context "with empty data structures" do
      let(:raw_data) { { "restaurants" => [] } }

      it "handles empty restaurants array" do
        expect(result).to eq([])
      end

      it "handles restaurant with no menus" do
        raw_data = {
          "restaurants" => [
            { "name" => "Empty Restaurant", "menus" => [] }
          ]
        }

        adapter = described_class.new(raw_data)
        result = adapter.adapt

        expect(result.first[:menus]).to eq([])
      end

      it "handles menu with no items" do
        raw_data = {
          "restaurants" => [
            {
              "name" => "Test",
              "menus" => [
                { "name" => "lunch", "menu_items" => [] }
              ]
            }
          ]
        }

        adapter = described_class.new(raw_data)
        result = adapter.adapt

        expect(result.first[:menus].first[:menu_items]).to eq([])
      end
    end

    context "with invalid data structures" do
      let(:adapter) { described_class.new("not a hash")}

      it "handles non-hash input" do
        expect(result).to eq([])
      end

      it "handles missing restaurants key" do
        adapter = described_class.new({ "wrong_key" => [] })

        expect(result).to eq([])
      end

      it "handles non-array restaurants value" do
        adapter = described_class.new({ "restaurants" => "not an array" })

        expect(result).to eq([])
      end
    end

    context "with missing or invalid prices" do
      let(:raw_data) do
        {
          "restaurants" => [
            {
              "name" => "Test",
              "menus" => [
                {
                  "name" => "lunch",
                  "menu_items" => [
                    { "name" => "Item 1", "price" => nil },
                    { "name" => "Item 2", "price" => 0 },
                    { "name" => "Item 3", "price" => "10.50" }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "handles various price formats" do
        items = result.first[:menus].first[:menu_items]

        expect(items[0][:price_in_cents]).to be_zero
        expect(items[1][:price_in_cents]).to be_zero
        expect(items[2][:price_in_cents]).to eq(10_50)
      end
    end
  end

  describe "#valid?" do
    let(:adapter) { described_class.new({ "restaurants" => [] }) }

    it "returns true when there are no errors" do
      expect(adapter).to be_valid
    end
  end

  describe "#errors" do
    let(:adapter) { described_class.new({ "restaurants" => [] }) }

    it "collects errors during adaptation" do
      expect(adapter.errors).to be_an(Array)
    end
  end
end
