require "rails_helper"

RSpec.describe Favorite, type: :model do
  let(:user) { create(:user) }
  let(:provider) { create(:provider) }

  it "creates a favorite successfully" do
    favorite = create(:favorite, user: user, provider: provider)
    expect(favorite.user).to eq(user)
    expect(favorite.provider).to eq(provider)
  end

  it "prevents duplicate favorites" do
    create(:favorite, user: user, provider: provider)
    duplicate = build(:favorite, user: user, provider: provider)
    expect(duplicate).not_to be_valid
  end

  it "allows same provider to be favorited by different users" do
    user2 = create(:user)
    create(:favorite, user: user, provider: provider)
    favorite2 = build(:favorite, user: user2, provider: provider)
    expect(favorite2).to be_valid
  end

  it "requires both user and provider" do
    expect(build(:favorite, user: nil, provider: provider)).not_to be_valid
    expect(build(:favorite, user: user, provider: nil)).not_to be_valid
  end
end
