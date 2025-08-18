require "rails_helper"

RSpec.describe ProvidersController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET #index" do
    let!(:health_provider) { create(:provider, service_type: "masseur", category: "Health & Wellness", hourly_rate: 50, location: "Bucharest") }
    let!(:beauty_provider) { create(:provider, service_type: "makeup_artist", category: "Beauty & Grooming", hourly_rate: 80, location: "Cluj-Napoca") }
    let!(:event_provider) { create(:provider, service_type: "dj", category: "Event Services", hourly_rate: 120, location: "Bucharest") }

    it "filters by category" do
      get :index, params: { category: "Health & Wellness" }

      expect(assigns(:providers)).to include(health_provider)
      expect(assigns(:providers)).not_to include(beauty_provider, event_provider)
    end

    it "filters by service type" do
      get :index, params: { service_type: "makeup_artist" }

      expect(assigns(:providers)).to include(beauty_provider)
      expect(assigns(:providers)).not_to include(health_provider, event_provider)
    end

    it "filters by category and service type together" do
      get :index, params: { category: "Event Services", service_type: "dj" }

      expect(assigns(:providers)).to include(event_provider)
      expect(assigns(:providers)).not_to include(health_provider, beauty_provider)
    end

    it "filters by price range" do
      get :index, params: { min_price: "70", max_price: "90" }

      expect(assigns(:providers)).to include(beauty_provider)
      expect(assigns(:providers)).not_to include(health_provider, event_provider)
    end

    it "filters by location" do
      get :index, params: { location: "Bucharest" }

      expect(assigns(:providers)).to include(health_provider, event_provider)
      expect(assigns(:providers)).not_to include(beauty_provider)
    end

    it "combines multiple filters" do
      get :index, params: {
        category: "Event Services",
        service_type: "dj",
        location: "Bucharest",
        min_price: "100"
      }

      expect(assigns(:providers)).to include(event_provider)
      expect(assigns(:providers)).not_to include(health_provider, beauty_provider)
    end

    it "populates service types when category is selected" do
      get :index, params: { category: "Event Services" }

      expect(assigns(:service_types)).to eq(["DJ", "Caterer", "Entertainer"])
    end

    it "preserves service type selection after filtering" do
      get :index, params: { category: "Beauty & Grooming", service_type: "makeup_artist" }

      expect(assigns(:service_types)).to eq(["Hairstylist", "Makeup Artist", "Nail Technician", "Eyelash Technician", "Facial Expert", "Tanning Specialist", "Barber"])
      expect(assigns(:providers)).to include(beauty_provider)
    end
  end

  describe "GET #service_types" do
    it "returns service types for a category" do
      get :service_types, params: { category: "Health & Wellness", frame_id: "test_frame" }, format: :turbo_stream

      expect(assigns(:service_types)).to eq(["Masseur", "Personal Trainer", "Nutritionist", "Yoga Instructor", "Chiropractor", "Physical Therapist"])
      expect(assigns(:frame_id)).to eq("test_frame")
    end

    it "returns empty array for invalid category" do
      get :service_types, params: { category: "Invalid Category", frame_id: "test_frame" }, format: :turbo_stream

      expect(assigns(:service_types)).to eq([])
    end
  end
end
