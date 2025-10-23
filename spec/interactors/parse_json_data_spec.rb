require "rails_helper"

RSpec.describe ParseJsonData do
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
      shared_examples "creates appropriate log messages" do |message|
        it "creates appropriate log messages" do
          expect(result.logs).to include(
            hash_including(level: :info, message: message)
          )
        end
      end

      it "successfully parses and adapts the JSON" do
        expect(result).to be_success
        expect(result.adapted_data).to be_an(Array)
        expect(result.adapted_data.size).to eq(1)
        expect(result.logs).to be_present
      end

      it_behaves_like "creates appropriate log messages", "Successfully parsed JSON data"
      it_behaves_like "creates appropriate log messages", "Successfully adapted 1 restaurant(s)"
    end

    context "with invalid JSON content" do
      let(:invalid_json) { "{ invalid json" }
      let(:json_content) { invalid_json }

      it "fails with an error message" do
        expect(result).to be_failure
        expect(result.message).to include("Invalid JSON format")
        expect(result.logs).to include(
          hash_including(level: :error, message: /JSON parsing failed/)
        )
      end
    end

    context "with missing JSON content" do
      shared_examples "fails with an error message" do
        it "fails with an error message" do
          expect(result).to be_failure
          expect(result.message).to eq("JSON content is required")
        end
      end

      context "when JSON content is nil" do
        let(:json_content) { nil }

        it_behaves_like "fails with an error message"
      end

      context "when JSON content is empty" do
        let(:json_content) { "" }

        it_behaves_like "fails with an error message"
      end
    end

    context "with valid JSON but invalid structure" do
      let(:json_content) { '{"not": "restaurants"}' }

      it "succeeds but returns empty adapted data" do
        expect(result).to be_success
        expect(result.adapted_data).to eq([])
      end
    end
  end
end
