require "rails_helper"

RSpec.describe "Favorites", type: :system do
  let(:user) { create(:user) }
  let(:provider) { create(:provider) }

  before do
    sign_in user
  end

  it "shows empty state when no favorites" do
    visit favorites_path
    expect(page).to have_content("No favorites yet")
  end

  it "displays favorites when present" do
    create(:favorite, user: user, provider: provider)
    visit favorites_path
    expect(page).to have_content("Your Favorites")
    expect(page).to have_content(provider.name)
  end

  # JavaScript test moved to request spec for better performance

  it "requires authentication" do
    sign_out user
    visit favorites_path
    expect(page).to have_current_path(new_user_session_path)
  end
end
