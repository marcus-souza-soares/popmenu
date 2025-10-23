require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe "rate limiting configuration" do
    it "has rate limit configured with correct parameters" do
      expect(ApplicationController::RATE_LIMIT_CONFIG[:to]).to eq(100)
      expect(ApplicationController::RATE_LIMIT_CONFIG[:within]).to eq(1.minute)
      expect(ApplicationController::RATE_LIMIT_CONFIG[:store]).to eq(Rails.cache)
    end
  end
end
