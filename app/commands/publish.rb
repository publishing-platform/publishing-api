module Commands
  class Publish < BaseCommand
    def call
      validate
      publish_edition
      after_transaction_commit { send_downstream }

      Success.new({ content_id: })
    end

  private

    def publish_edition
      delete_change_notes unless edition.update_type == "major"
      previous_edition.supersede if previous_edition

      unless edition.pathless?
        redirect_old_base_path
        clear_published_items_of_same_base_path
      end

      set_publishing_request_id
      set_timestamps
      edition.publish
      remove_draft_access
      create_publish_action
    end

    def orphaned_content_ids
      return [] unless previous_edition

      previous_links = previous_edition.links.map(&:target_content_id)
      current_links = edition.links.map(&:target_content_id)
      previous_links - current_links
    end

    def create_publish_action
      Action.create_publish_action(edition, event)
    end

    def remove_draft_access
      edition.update!(auth_bypass_ids: []) if edition.auth_bypass_ids.any?
    end

    def validate
      no_draft_item_exists unless edition
      check_version_and_raise_if_conflicting(document, previous_version_number)
    end

    def edition
      document.draft
    end

    def previous_edition
      document.published_or_unpublished
    end

    def redirect_old_base_path
      return unless previous_edition

      previous_base_path = previous_edition.base_path

      if previous_base_path != edition.base_path
        publish_redirect(previous_base_path)
      end
    end

    def no_draft_item_exists
      if already_published?
        message = "Cannot publish an already published edition"
        raise_command_error(409, message, { fields: {} })
      else
        message = "Item with content_id #{content_id} does not exist"
        raise_command_error(404, message, { fields: {} })
      end
    end

    def delete_change_notes
      ChangeNote.where(edition:).delete_all
    end

    def document
      @document ||= Document.find_or_create_locked(
        content_id: payload[:content_id],
      )
    end

    def content_id
      document.content_id
    end

    def previous_version_number
      payload[:previous_version].to_i if payload[:previous_version]
    end

    def already_published?
      document.editions.exists?(state: "published")
    end

    def clear_published_items_of_same_base_path
      SubstitutionHelper.clear!(
        new_item_document_type: edition.document_type,
        new_item_content_id: document.content_id,
        state: %w[published unpublished],
        base_path: edition.base_path,
        downstream:,
        callbacks:,
        nested: true,
      )
    end

    def set_timestamps
      Edition::Timestamps.live_transition(edition, edition.update_type, previous_edition)
    end

    def set_publishing_request_id
      edition.update!(
        publishing_request_id: PublishingPlatformApi::PublishingPlatformHeaders.headers[:publishing_platform_request_id],
      )
    end

    def publish_redirect(previous_base_path)
      draft_redirect = Edition.with_document.find_by(
        state: "draft",
        base_path: previous_base_path,
        schema_name: "redirect",
      )

      if draft_redirect
        self.class.call(
          {
            content_id: draft_redirect.document.content_id,
          },
          downstream:,
          callbacks:,
          nested: true,
        )
      end
    end

    def edition_diff
      @edition_diff ||= LinkExpansion::EditionDiff.new(edition, previous_edition:)
    end

    def send_downstream
      return unless downstream

      DownstreamDraftJob.perform_async(
        worker_params,
      )

      DownstreamLiveWorker.perform_async(
        live_worker_params,
      )
    end

    def live_worker_params
      worker_params.merge(
        "orphaned_content_ids" => orphaned_content_ids,
      )
    end

    def worker_params
      {
        "content_id" => content_id,
        "update_dependencies" => edition_diff.present?,
        "source_command" => "publish",
        "source_fields" => edition_diff.has_previous_edition? ? edition_diff.fields.map(&:to_s) : [],
      }
    end
  end
end
