require "rails_helper"

RSpec.describe Availability, type: :model do
  describe "validations" do
    it "is invalid when start_time is not before end_time" do
      availability = build(:availability, start_time: "10:00", end_time: "09:00")
      expect(availability).not_to be_valid
      expect(availability.errors[:end_time]).to include("must be after start time")
    end
  end

  describe "#available?" do
    it "returns the available flag" do
      availability = build(:availability, available: true)
      expect(availability.available?).to be(true)
    end
  end
end
