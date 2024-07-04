class PutContent < BaseCommand
  def call
    remove_previous_path_reservations
    reserve_current_path
    edition = create_or_update_edition

    update_content_dependencies(edition)

    after_transaction_commit do
      # TODO
      puts "after committed - send downstream"
    end  
    
    # TODO
    # Success.new(present_response(edition))  
    Success.new({})  
  end

  def document
    @document ||= Document.find_or_create_locked(
      content_id: payload.fetch(:content_id)
    )
  end  

private

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
    # create_redirect
    ChangeNote.create_from_edition(payload, edition)
    # create_links(edition)
    # Action.create_put_content_action(edition, document.locale, event)
  end  

  def create_or_update_edition
    if previous_drafted_edition
      # TODO
      # @links_before_update = previous_drafted_edition.links.map(&:target_content_id)
      updated_item, @previous_edition = UpdateExistingDraftEdition.new(previous_drafted_edition, self, payload).call
    else
      # TODO
      # @links_before_update = previously_published_edition.links.map(&:target_content_id)
      new_draft_edition = CreateDraftEdition.new(self, payload, previously_published_edition).call
    end
    @edition = updated_item || new_draft_edition
  end  
end