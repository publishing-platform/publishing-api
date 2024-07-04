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
    major_published_at
    phase    
    public_updated_at    
    published_at
    publishing_app
    redirects
    rendering_app
    routes
    schema_name
    state
    title
    user_facing_version
    update_type
  ].freeze  

  enum content_store: {
    draft: "draft",
    live: "live",
  }

  belongs_to :document
  has_one :change_note
  has_many :links, dependent: :delete_all

  validates :document, presence: true

  scope :with_change_note, -> { left_outer_joins(:change_note) }
end