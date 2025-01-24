FactoryBot.define do
  factory :expanded_links do
    content_id { SecureRandom.uuid }
    with_drafts { false }
  end
end
