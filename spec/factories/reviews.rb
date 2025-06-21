FactoryBot.define do
  factory :review do
    association :user
    association :provider
    association :appointment
    rating { 5 }
    content { "Great service provided!" }
  end
end
