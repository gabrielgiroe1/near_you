FactoryBot.define do
  factory :availability do
    association :provider
    day_of_week { "Monday" }
    start_time { Time.zone.parse("08:00") }
    end_time { Time.zone.parse("09:00") }
    available { true }
    session_duration { 60 }
  end
end
