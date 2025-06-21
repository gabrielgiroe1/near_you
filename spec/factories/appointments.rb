FactoryBot.define do
  factory :appointment do
    association :user
    association :provider
    start_time { Time.zone.parse("2023-01-01 10:00") }
    status { :pending }
  end
end
