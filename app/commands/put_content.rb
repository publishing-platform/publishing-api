class PutContent < BaseCommand
  def call
    remove_previous_path_reservations
    reserve_current_path
    clear_draft_items_of_same_base_path
    edition = create_or_update_edition

    update_content_dependencies(edition)

    orphaned_links = link_diff_between(
      @links_before_update,
      edition.links.map(&:target_content_id),
    )

    after_transaction_commit do
      send_downstream(
        document.content_id,
        orphaned_links,
      )
    end

    # TODO
    # Success.new(present_response(edition))
    Success.new({})
  end

  def document
    @document ||= Document.find_or_create_locked(
      content_id: payload.fetch(:content_id),
    )
  end

private

  def link_diff_between(old_links, new_links)
    old_links - new_links
  end

  def previous_drafted_edition
    document.draft
  end

  def previously_published_edition
    @previously_published_edition ||= PreviouslyPublishedItem.new(
      document, payload[:base_path], self
    ).call
  end

  def remove_previous_path_reservations
    to_discard = previous_drafted_edition&.base_path
    return if to_discard.blank? || to_discard == payload[:base_path]
    return if Edition.exists?(base_path: to_discard,
                              content_store: :live,
                              publishing_app: payload[:publishing_app])

    PathReservation.where(base_path: to_discard, publishing_app: payload[:publishing_app])
                  .delete_all
  end

  def reserve_current_path
    return unless payload[:base_path]

    PathReservation.reserve_base_path!(payload[:base_path], payload[:publishing_app])
  end

  def update_content_dependencies(edition)
    create_redirect
    ChangeNote.create_from_edition(payload, edition)
    create_links(edition)
    Action.create_put_content_action(edition, event)
  end

  def create_links(edition)
    return if payload[:links].nil?

    payload[:links].each do |link_type, target_link_ids|
      edition.links.create!(
        target_link_ids.map.with_index do |target_link_id, i|
          { link_type:, target_content_id: target_link_id, position: i }
        end,
      )
    end
  end

  def create_redirect
    return unless payload[:base_path]

    RedirectService.new(
      previously_published_edition,
      payload,
      callbacks,
    ).call
  end

  def create_or_update_edition
    if previous_drafted_edition
      @links_before_update = previous_drafted_edition.links.map(&:target_content_id)
      updated_item, @previous_edition = UpdateExistingDraftEdition.new(previous_drafted_edition, self, payload).call
    else
      @links_before_update = previously_published_edition.links.map(&:target_content_id)
      new_draft_edition = CreateDraftEdition.new(self, payload, previously_published_edition).call
    end
    @edition = updated_item || new_draft_edition
  end

  def clear_draft_items_of_same_base_path
    return unless payload[:base_path]

    SubstitutionHelper.clear!(
      new_item_document_type: payload[:document_type],
      new_item_content_id: document.content_id,
      state: "draft",
      base_path: payload[:base_path],
      downstream:,
      callbacks:,
      nested: true,
    )
  end

  def edition_diff
    @edition_diff ||= LinkExpansion::EditionDiff.new(@edition, previous_edition: @previous_edition)
  end

  def send_downstream(content_id, orphaned_links)
    return unless downstream

    DownstreamDraftWorker.perform_async(
      "content_id" => content_id,
      "update_dependencies" => edition_diff.present?, # has the information that would be presented on documents linking to this document changed?
      "orphaned_content_ids" => orphaned_links,
      "source_command" => "put_content",
      "source_fields" => edition_diff.has_previous_edition? ? edition_diff.fields.map(&:to_s) : [],
    )
  end
end
