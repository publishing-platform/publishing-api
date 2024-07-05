class Action < ApplicationRecord
  belongs_to :edition, optional: true
  belongs_to :link_set, optional: true
  belongs_to :event

  validate :one_of_edition_link_set
  validates :action, presence: true

  def self.create_put_content_action(updated_draft, event)
    create_publishing_action("PutContent", updated_draft, event)
  end

  def self.create_publish_action(edition, event)
    create_publishing_action("Publish", edition, event)
  end

  def self.create_republish_action(edition, event)
    create_publishing_action("Republish", edition, event)
  end

  def self.create_unpublish_action(edition, unpublishing_type, event)
    action = "Unpublish#{unpublishing_type.camelize}"
    create_publishing_action(action, edition, event)
  end

  def self.create_discard_draft_action(edition, event)
    create_publishing_action("DiscardDraft", edition, event)
  end

  def self.create_publishing_action(action, edition, event)
    create!(
      content_id: edition.document.content_id,
      action:,
      user_uid: event.user_uid,
      edition:,
      event:,
    )
  end

  def self.create_patch_link_set_action(link_set, _before_links, event)
    create!(
      content_id: link_set.content_id,
      locale: nil,
      action: "PatchLinkSet",
      user_uid: event.user_uid,
      link_set:,
      event:,
    )

    # TODO
    # after_links = link_set.links.to_a
    # LinkChangeService.new(action, before_links, after_links).record
  end

private

  def one_of_edition_link_set
    if edition_id && link_set_id || edition && link_set
      errors.add(:base, "can not be associated with both an edition and link set")
    end
  end
end
