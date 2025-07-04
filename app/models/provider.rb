class Provider < ApplicationRecord
  belongs_to :user
  has_many :appointments, dependent: :destroy
  has_many :availabilities, dependent: :destroy
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
  has_many :reviews, dependent: :destroy
  has_many :review_responses, dependent: :destroy
  has_many_attached :images
  has_one_attached :profile_picture

  validates :user_id, uniqueness: true, presence: true

  enum :stripe_status, { incomplete: "incomplete", active: "active" }

  enum :service_type, {
    # Health & Wellness
    masseur: "Masseur",
    personal_trainer: "Personal Trainer",
    nutritionist: "Nutritionist",
    yoga_instructor: "Yoga Instructor",
    chiropractor: "Chiropractor",
    physical_therapist: "Physical Therapist",

    # Beauty & Grooming
    hairstylist: "Hairstylist",
    makeup_artist: "Makeup Artist",
    nail_technician: "Nail Technician",
    eyelash_technician: "Eyelash Technician",
    facial_expert: "Facial Expert",
    tanning_specialist: "Tanning Specialist",
    barber: "Barber",

    # Home Services
    electrician: "Electrician",
    plumber: "Plumber",
    gardener: "Gardener",
    house_cleaner: "House Cleaner",
    handyman: "Handyman",
    painter: "Painter",
    window_cleaner: "Window Cleaner",

    # Education
    tutor: "Tutor",
    music_teacher: "Music Teacher",
    language_coach: "Language Coach",
    coding_instructor: "Coding Instructor",
    art_instructor: "Art Instructor",

    # Creative Services
    photographer: "Photographer",
    videographer: "Videographer",
    event_decorator: "Event Decorator",
    florist: "Florist",

    # Event Services
    dj: "DJ",
    caterer: "Caterer",
    entertainer: "Entertainer",

    # Specialty & Miscellaneous
    translator: "Translator",
    pet_groomer: "Pet Groomer",
    tailor: "Tailor"
  }

  # rubocop:disable Style/HashSyntax
  def self.categories
    {
      :"Health & Wellness" => [
        "Masseur", "Personal Trainer", "Nutritionist",
        "Yoga Instructor", "Chiropractor", "Physical Therapist"
      ],
      :"Beauty & Grooming" => [
        "Hairstylist", "Makeup Artist", "Nail Technician",
        "Eyelash Technician", "Facial Expert", "Tanning Specialist",
        "Barber"
      ],
      :"Home Services" => [
        "Electrician", "Plumber", "Gardener", "House Cleaner",
        "Handyman", "Painter", "Window Cleaner"
      ],
      :Education => [
        "Tutor", "Music Teacher", "Language Coach",
        "Coding Instructor", "Art Instructor"
      ],
      :"Creative Services" => [
        "Photographer", "Videographer", "Event Decorator", "Florist"
      ],
      :"Event Services" => [
        "DJ", "Caterer", "Entertainer"
      ],
      :"Specialty & Miscellaneous" => [
        "Translator",
        "Pet Groomer", "Tailor"
      ]
    }
  end

  def recalculate_average_rating!
    update!(rating: reviews.average(:rating).to_f.round(2))
  end
end
