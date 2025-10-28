require "rails_helper"

RSpec.describe Provider, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  describe ".categories" do
    it "returns a hash of categories" do
      categories = described_class.categories
      expect(categories).to be_a(Hash)
      expect(categories.keys).to include(:"Health & Wellness")
      expect(categories[:"Health & Wellness"]).to include("Masseur")
    end
  end

  describe ".service_type_to_enum_key" do
    it "converts human-readable service types to enum keys" do
      expect(described_class.service_type_to_enum_key("Personal Trainer")).to eq("personal_trainer")
      expect(described_class.service_type_to_enum_key("Makeup Artist")).to eq("makeup_artist")
      expect(described_class.service_type_to_enum_key("DJ")).to eq("dj")
      expect(described_class.service_type_to_enum_key("Pet Groomer")).to eq("pet_groomer")
    end

    it "returns nil for invalid service types" do
      expect(described_class.service_type_to_enum_key("Invalid Service")).to be_nil
      expect(described_class.service_type_to_enum_key("")).to be_nil
      expect(described_class.service_type_to_enum_key(nil)).to be_nil
    end
  end

  describe "#next_available_day" do
    let(:user) { create(:user) }
    let(:provider) { create(:provider, user: user, service_type: "masseur") }

    it "returns today if provider is available today" do
      # Set time to 10 AM to ensure there are available slots later in the day
      travel_to Time.current.beginning_of_day + 10.hours do
        create(:availability,
          provider: provider,
          day_of_week: Date.current.strftime("%A"),
          available: true,
          start_time: Time.current.beginning_of_day + 9.hours,
          end_time: Time.current.beginning_of_day + 17.hours,
          session_duration: 60
        )

        expect(provider.next_available_day).to eq(Date.current)
      end
    end

    it "returns nil if no availability within 2 weeks" do
      expect(provider.next_available_day).to be_nil
    end
  end

  describe "#next_available_day_text" do
    let(:user) { create(:user) }
    let(:provider) { create(:provider, user: user, service_type: "masseur") }

    it "returns 'Available today' for today" do
      allow(provider).to receive(:next_available_day).and_return(Date.current)
      expect(provider.next_available_day_text).to eq("Available today")
    end

    it "returns 'Available tomorrow' for tomorrow" do
      allow(provider).to receive(:next_available_day).and_return(Date.current + 1.day)
      expect(provider.next_available_day_text).to eq("Available tomorrow")
    end

    it "returns 'No availability yet' when no slots available" do
      allow(provider).to receive(:next_available_day).and_return(nil)
      expect(provider.next_available_day_text).to eq("No availability yet")
    end
  end
end
