FactoryBot.define do
  factory :action do
    content_id { SecureRandom.uuid }
    action { "Action" }
    user_uid { SecureRandom.uuid }
    event
  end
end
