class ExpandedLinks < ApplicationRecord
  include FindOrCreateLocked

  def self.locked_update(
    content_id:,
    with_drafts:,
    payload_version:,
    expanded_links:
  )
    transaction do
      entry = find_or_create_locked(
        content_id:,
        with_drafts:,
      )

      next unless entry.payload_version <= payload_version

      entry.update!(
        payload_version:,
        expanded_links:,
      )
    end
  end
end
