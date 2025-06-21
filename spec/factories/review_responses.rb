FactoryBot.define do
  factory :review_response do
    association :review
    association :provider
    content { 'Thank you for the feedback!' }
  end
end
