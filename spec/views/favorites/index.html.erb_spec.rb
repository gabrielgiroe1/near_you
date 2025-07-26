require "rails_helper"

RSpec.describe "favorites/index.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:provider) { create(:provider, name: "John Doe") }

  before do
    allow(view).to receive_messages(current_user: user, pagy_nav: "")
  end

  it "shows empty state when no favorites" do
    assign(:favorites, [])
    assign(:pagy, nil)
    render
    expect(rendered).to include("No favorites yet")
  end

  it "displays favorites when present" do
    favorite = create(:favorite, user: user, provider: provider)
    assign(:favorites, [favorite])
    assign(:pagy, nil)
    render
    expect(rendered).to include("Your Favorites")
    expect(rendered).to include("John Doe")
  end

  it "renders favorite button partial" do
    favorite = create(:favorite, user: user, provider: provider)
    assign(:favorites, [favorite])
    assign(:pagy, nil)
    render
    expect(view).to render_template(partial: "favorites/_favorite_button")
  end
end
