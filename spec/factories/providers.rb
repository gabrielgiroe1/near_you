FactoryBot.define do
  factory :provider do
    association :user
    service_type { Provider.service_types.keys.first }
    name { Faker::Name.name }
    hourly_rate { Faker::Number.between(from: 50, to: 200) }
    bio { Faker::Lorem.paragraph }
    location { Faker::Address.city }

    trait :with_stripe_account do
      stripe_account_id { "acct_test_#{SecureRandom.hex(8)}" }
      stripe_status { :active }
      charges_enabled { true }
      payouts_enabled { true }
    end

    trait :incomplete_stripe do
      stripe_account_id { "acct_test_#{SecureRandom.hex(8)}" }
      stripe_status { :incomplete }
      charges_enabled { false }
      payouts_enabled { false }
    end
  end
end
