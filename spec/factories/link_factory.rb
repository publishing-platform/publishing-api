FactoryBot.define do
  factory :link do
    link_set
    target_content_id { SecureRandom.uuid }
    link_type         { "primary_publishing_organisation" }
  end
end
