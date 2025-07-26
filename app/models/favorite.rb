class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :provider
  validates :user_id, uniqueness: { scope: :provider_id }
end
