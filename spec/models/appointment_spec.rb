require "rails_helper"

RSpec.describe Appointment, type: :model do
  describe "#set_end_time" do
    it "sets end_time based on provider session_duration" do
      provider = create(:provider)
      create(:availability, provider: provider, session_duration: 30)
      appointment = build(:appointment, provider: provider, start_time: Time.zone.parse("2023-01-01 10:00"))
      appointment.send(:set_end_time)
      expect(appointment.end_time).to eq(appointment.start_time + 30.minutes)
    end
  end
end
