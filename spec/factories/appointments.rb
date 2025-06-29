FactoryBot.define do
  factory :appointment do
    association :user
    association :provider
    start_time { Time.zone.parse("2023-01-01 10:00") }
    status { :pending }

    trait :with_stripe_session do
      stripe_session_id { "cs_test_#{SecureRandom.hex(8)}" }
      stripe_payment_intent_id { "pi_test_#{SecureRandom.hex(8)}" }
    end

    trait :confirmed do
      status { :confirmed }
      stripe_session_id { "cs_test_#{SecureRandom.hex(8)}" }
      stripe_payment_intent_id { "pi_test_#{SecureRandom.hex(8)}" }
    end

    trait :refunded do
      status { :cancelled }
      stripe_session_id { "cs_test_#{SecureRandom.hex(8)}" }
      stripe_payment_intent_id { "pi_test_#{SecureRandom.hex(8)}" }
      stripe_refund_id { "re_test_#{SecureRandom.hex(8)}" }
      refunded_at { 1.hour.ago }
    end
  end
end
