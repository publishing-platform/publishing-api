module Commands
  class Republish < BaseCommand
    delegate :content_id, to: :document

    def call
      validate
      republish_edition
      after_transaction_commit { send_downstream } if downstream

      Success.new({ content_id: })
    end

  private

    def document
      @document ||= Document.find_or_create_locked(
        content_id: payload[:content_id],
      )
    end

    def edition
      document.live
    end

    def validate
      no_republishable_item_exists unless edition
      previous_version_number = payload[:previous_version].to_i if payload[:previous_version]
      check_version_and_raise_if_conflicting(document, previous_version_number)
    end

    def no_republishable_item_exists
      message = "A live item with content_id #{content_id} does not exist"
      raise_command_error(404, message, { fields: {} })
    end

    def republish_edition
      overwrite_publishing_request_id
      edition.unpublishing.destroy! if edition.unpublishing
      edition.publish
      create_republish_action
    end

    def overwrite_publishing_request_id
      edition.update!(
        publishing_request_id: PublishingPlatformApi::PublishingPlatformHeaders.headers[:publishing_platform_request_id],
      )
    end

    def create_republish_action
      Action.create_republish_action(edition, event)
    end

    def send_downstream
      unless document.draft
        DownstreamDraftWorker.perform_async(
          "content_id" => content_id,
          "update_dependencies" => true,
          "source_command" => "republish",
        )
      end

      DownstreamLiveWorker.perform_async(
        "content_id" => content_id,
        "update_dependencies" => true,
        "source_command" => "republish",
      )
    end
  end
end
