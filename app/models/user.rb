class User < ApplicationRecord
  has_one :provider, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
  has_many :reviews, dependent: :destroy
  has_one_attached :profile_picture

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable

  enum :role, { user: 0, provider: 1, admin: 2 }

  after_initialize do
    self.role ||= :user if new_record?
  end

  def provider?
    role == "provider"
  end

  def user?
    role == "user"
  end
end
