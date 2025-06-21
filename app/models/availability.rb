class Availability < ApplicationRecord
  belongs_to :provider

  validates :day_of_week, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :available, inclusion: { in: [true, false] }
  validate :start_time_before_end_time

  # Add day of week validation
  validates :day_of_week, inclusion: {
    in: %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday],
    message: "%{value} is not a valid day of week"
  }

  before_save :set_available_default

  def available?
    available
  end

  private

  def set_available_default
    self.available = true if available.nil?
  end

  def start_time_before_end_time
    errors.add(:end_time, "must be after start time") if start_time && end_time && start_time >= end_time
  end
end
