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

  scope :with_document, -> { joins(:document) }
  scope :with_change_note, -> { left_outer_joins(:change_note) }

  # TODO: - more validation
  validates :document, presence: true

  delegate :content_id, to: :document

  def unpublish(type:, explanation: nil, alternative_path: nil, redirects: nil, unpublished_at: nil)
    content_store = type == "substitute" ? nil : "live"
    update!(state: "unpublished", content_store:)

    if unpublishing.present?
      unpublishing.update!(
        type:,
        explanation:,
        alternative_path:,
        redirects:,
        unpublished_at:,
      )
      unpublishing
    else
      Unpublishing.create!(
        edition: self,
        type:,
        explanation:,
        alternative_path:,
        redirects:,
        unpublished_at:,
      )
    end
  end

  def substitute
    unpublish(
      type: "substitute",
      explanation: "Automatically unpublished to make way for another document",
    )
  end

  def unpublished?
    state == "unpublished" && unpublishing.present?
  end
end
