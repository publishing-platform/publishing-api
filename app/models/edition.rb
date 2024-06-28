class Edition < ApplicationRecord
  include SymbolizeJson

  TOP_LEVEL_FIELDS = %i[
    auth_bypass_ids
    base_path
    content_store
    description
    details
    document_type
    first_published_at
    last_edited_at
    published_at
    publishing_app
    redirects
    rendering_app
    routes
    schema_name
    state
    title
    user_facing_version
  ].freeze  

  enum content_store: {
    draft: "draft",
    live: "live",
  }

  belongs_to :document

  validates :document, presence: true
end