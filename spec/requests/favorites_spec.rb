require "rails_helper"

RSpec.describe "Favorites", type: :request do
  let(:user) { create(:user) }
  let(:provider) { create(:provider) }

  before do
    sign_in user
  end

  it "shows favorites index" do
    get "/favorites"
    expect(response).to have_http_status(:success)
  end

  it "creates a favorite" do
    expect {
      post provider_favorite_path(provider)
    }.to change(Favorite, :count).by(1)
  end

  it "removes a favorite" do
    create(:favorite, user: user, provider: provider)
    expect {
      delete provider_unfavorite_path(provider)
    }.to change(Favorite, :count).by(-1)
  end

  it "requires authentication" do
    sign_out user
    post provider_favorite_path(provider)
    expect(response).to redirect_to(new_user_session_path)
  end
end
