module Queries
  module FindContentIdsOnStore
    # Returns content ids if found on any of the given content stores, ordered by content id.
    def self.call(content_ids, content_stores = %w[draft live])
      Document.joins(:editions)
        .where(
          content_id: content_ids,
          editions: { content_store: content_stores },
        )
        .distinct
        .order(:content_id)
        .pluck(:content_id)
    end
  end
end
