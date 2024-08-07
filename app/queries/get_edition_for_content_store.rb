module Queries
  class GetEditionForContentStore
    def self.call(content_id, include_draft: false)
      allowed_content_stores = [:live]
      allowed_content_stores << :draft if include_draft

      Edition
        .with_document
        .with_unpublishing
        .where(documents: { content_id: })
        .where(content_store: allowed_content_stores)
        .where("unpublishings.type IS NULL OR unpublishings.type != 'substitute'")
        .order(user_facing_version: :desc)
        .first
    end
  end
end