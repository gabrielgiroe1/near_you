class Provider < ApplicationRecord
  belongs_to :user
  has_many :appointments, dependent: :destroy
  has_many :availabilities, dependent: :destroy
  has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
  has_many :favorites, dependent: :destroy
  has_many :favorited_by, through: :favorites, source: :user
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

  # Convert human-readable service type to enum key
  def self.service_type_to_enum_key(human_readable_type)
    return nil if human_readable_type.blank?

    # Convert to snake_case format that matches the enum
    snake_case = human_readable_type.downcase
      .gsub(/\s+/, "_")
      .gsub(/[^a-z0-9_]/, "")

    # Return the key if it exists in the enum, otherwise nil
    service_types.key?(snake_case) ? snake_case : nil
  end

  def recalculate_average_rating!
    update!(rating: reviews.average(:rating).to_f.round(2))
  end

  def can_accept_bookings?
    stripe_account_id.present? && stripe_status == "active"
  end

  def next_available_day
    # Start from today
    current_date = Date.current

    # Check up to 2 weeks ahead
    (0..14).each do |days_ahead|
      check_date = current_date + days_ahead.days
      day_name = check_date.strftime("%A")

      # Find availability for this day of the week
      availability = availabilities.find_by(day_of_week: day_name, available: true)
      next unless availability

      # Check if there are any available time slots for this day
      if has_available_slots?(check_date, availability)
        return check_date
      end
    end

    nil # No availability found in the next 2 weeks
  end

  def next_available_day_text
    next_day = next_available_day
    return "No availability yet" unless next_day

    case next_day
      when Date.current
      "Available today"
      when Date.current + 1.day
      "Available tomorrow"
      when (Date.current + 2.days)..(Date.current + 6.days)
      "Available #{next_day.strftime('%A')}"
      else
      "Available #{next_day.strftime('%b %d')}"
    end
  end

  private

  def has_available_slots?(date, availability)
    # Generate time slots for the day
    current_time = DateTime.new(
      date.year, date.month, date.day,
      availability.start_time.hour, availability.start_time.min
    )

    end_time = DateTime.new(
      date.year, date.month, date.day,
      availability.end_time.hour, availability.end_time.min
    )

    session_duration = availability.session_duration || 60

    # Check if any slot is available
    while current_time + session_duration.minutes <= end_time
      slot_end_time = current_time + session_duration.minutes

      # Skip past slots if checking today
      if date == Date.current && current_time <= Time.current
        current_time += session_duration.minutes
        next
      end

      # Check if this slot is free (no overlapping appointments)
      unless appointments.active.overlapping(current_time, slot_end_time).exists?
        return true
      end

      current_time += session_duration.minutes
    end

    false
  end
end
