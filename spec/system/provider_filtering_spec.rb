require "rails_helper"

RSpec.describe "Provider Filtering", :js, type: :system do
  let(:user) { create(:user, role: "user") }
  let!(:masseur) { create(:provider, service_type: "masseur", category: "Health & Wellness", hourly_rate: 50, location: "Bucharest") }
  let!(:nutritionist) { create(:provider, service_type: "nutritionist", category: "Health & Wellness", hourly_rate: 80, location: "Cluj-Napoca") }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in user
  end

  def open_filters
    click_button "Filters & Search"
    expect(page).to have_css("#filters-form")
  end

  it "opens filtered results from the Masaj category" do
    visit providers_path
    click_link "Masaj"

    expect(page).to have_current_path(
                    providers_path(service_type: "Masseur"),
                    ignore_query: false
                  )

    open_filters

    expect(page).to have_content("Masseur Providers")
    within("turbo-frame#providers") do
      expect(page).to have_content("Masseur")
    end
  end

  it "filters providers by price range" do
    visit providers_path(category: "Health & Wellness")
    open_filters

    within("#filters-form") do
      fill_in "min_price", with: "70"
      fill_in "max_price", with: "90"
      click_button "Apply Price Filter"
    end

    expect(page).to have_content("1 provider available")

    within("turbo-frame#providers") do
      expect(page).to have_content("Nutritionist")
      expect(page).to have_content("80.0 RON")
      expect(page).not_to have_content("Masseur")
      expect(page).not_to have_content("50.0 RON")
    end
  end

  it "displays availability information on provider cards" do
    visit providers_path(category: "Health & Wellness")

    within("turbo-frame#providers") do
      expect(page).to have_text("No availability yet", count: 2)
    end
  end

  it "displays provider cards" do
    visit providers_path(category: "Health & Wellness")

    expect(page).to have_content("2 providers available")

    within("turbo-frame#providers") do
      expect(page).to have_content("Masseur")
      expect(page).to have_content("Nutritionist")
      expect(page).to have_link(href: provider_path(masseur))
      expect(page).to have_link(href: provider_path(nutritionist))
    end
  end
end
