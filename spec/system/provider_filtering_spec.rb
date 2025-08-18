require "rails_helper"

RSpec.describe "Provider Filtering", :js, type: :system do
  let(:user) { create(:user, role: "user") }
  let!(:health_provider) { create(:provider, service_type: "masseur", category: "Health & Wellness", hourly_rate: 50, location: "Bucharest") }
  let!(:beauty_provider) { create(:provider, service_type: "makeup_artist", category: "Beauty & Grooming", hourly_rate: 80, location: "Cluj-Napoca") }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
    visit providers_path
  end

  it "filters providers by price range" do
    within("#filters-form") do
      fill_in "min_price", with: "70"
      fill_in "max_price", with: "90"
      click_button "Apply Price Filter"
    end

    # Should show only beauty provider (hourly_rate: 80)
    expect(page).to have_content("1 provider available")
    expect(page).to have_content("80.0 RON/hr")
    expect(page).not_to have_content("50.0 RON/hr")
  end

  it "displays availability information" do
    # Check that availability text is shown (using SVG icons)
    expect(page).to have_css("svg")
    expect(page).to have_text("No availability yet") # Since no availabilities are set up
  end

  it "displays provider listings" do
    # Basic test that providers are shown
    expect(page).to have_content("Makeup Artist")
    expect(page).to have_content("Masseur")
    expect(page).to have_content("2 providers available")
  end
end
