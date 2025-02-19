module Commands
  class PatchLinkSet < BaseCommand
    def call
      raise_unless_links_hash_is_provided
      validate_schema
      link_set = LinkSet.find_or_create_locked(content_id:)
      check_version_and_raise_if_conflicting(link_set, previous_version_number)

      link_set.increment!(:stale_lock_version)

      before_links = link_set.links.to_a

      grouped_links.each do |group, payload_content_ids|
        # For each set of links in a LinkSet scoped by link_type, this iterator
        # deletes the entire existing set and then imports all the links in the
        # payload, preserving their ordering.
        link_set.links.where(link_type: group).delete_all

        payload_content_ids.uniq.each_with_index do |content_id, i|
          link_set.links.create!(target_content_id: content_id, link_type: group, position: i)
        end
      end

      # we need to reload the link_set as the links association will be stale
      link_set.reload

      orphaned_content_ids = link_diff_between(before_links.map(&:target_content_id), link_set.links.map(&:target_content_id))
      update_dependencies = link_set.links_changed?(before_links)

      after_transaction_commit do
        send_downstream(orphaned_content_ids, update_dependencies)
      end

      Action.create_patch_link_set_action(link_set, before_links, event)

      presented = Presenters::Queries::LinkSetPresenter.present(link_set)
      Success.new(presented)
    end

  private

    def link_diff_between(links_before_patch, links_after_patch)
      links_before_patch - links_after_patch
    end

    def content_id
      payload.fetch(:content_id)
    end

    def document
      @document ||= Document.find_by(content_id:)
    end

    def grouped_links
      payload[:links]
    end

    def previous_version_number
      payload[:previous_version].to_i if payload[:previous_version]
    end

    def raise_unless_links_hash_is_provided
      unless grouped_links.is_a?(Hash)
        raise CommandError.new(
          code: 422,
          message: "Links are required",
          error_details: {
            error: {
              code: 422,
              message: "Links are required",
              fields: {
                links: ["are required"],
              },
            },
          },
        )
      end
    end

    def send_downstream(orphaned_content_ids, update_dependencies)
      return unless downstream

      params = worker_params.merge(
        {
          "orphaned_content_ids" => orphaned_content_ids,
          "update_dependencies" => update_dependencies,
        },
      )

      if document.draft || document.live
        DownstreamDraftJob.perform_async(params)
      end

      if document.live
        DownstreamLiveWorker.perform_async(params)
      end
    end

    def worker_params
      {
        "content_id" => content_id,
        "source_command" => "patch_link_set",
      }
    end

    def validate_schema
      return if schema_validator.valid?

      message = "The payload did not conform to the schema"
      raise CommandError.new(
        code: 422,
        message:,
        error_details: schema_validator.errors,
      )
    end

    def schema_validator
      @schema_validator ||= SchemaValidator.new(
        payload: { links: payload[:links] },
        schema_name:,
        schema_type: :links,
      )
    end

    def schema_name
      @schema_name ||= Queries::GetLatest.call(
        Edition.with_document.where("documents.content_id": content_id),
      ).pick(:schema_name)
    end
  end
end
