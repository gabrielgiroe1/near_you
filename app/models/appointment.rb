class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :provider
  has_many :reviews, dependent: :destroy

  enum :status, { pending: 0, confirmed: 1, completed: 2, cancelled: 3 }

  # Virtual attribute for appointment duration
  attr_accessor :duration

  before_save :set_end_time
  validate :time_slot_available, on: :create

  scope :active, -> { where(status: [:pending, :confirmed]) }
  scope :overlapping, ->(start_time, end_time) {
    where("(start_time, end_time) OVERLAPS (?, ?)", start_time, end_time)
  }

  private

  def set_end_time
    return unless start_time
    # Default to provider's session duration or 60 minutes
    duration_minutes = provider&.availabilities&.first&.session_duration || 60
    self.end_time = start_time + duration_minutes.minutes
  end

  def time_slot_available
    return unless start_time && end_time

    overlapping_appointments = provider.appointments.active.overlapping(start_time, end_time).where.not(id: id)

    if overlapping_appointments.exists?
      errors.add(:start_time, "is already booked")
    end
  end
end
