FactoryBot.define do
  factory :provider do
    association :user
    service_type { Provider.service_types.keys.first }
  end
end
