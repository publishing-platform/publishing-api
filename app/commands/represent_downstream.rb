module Commands
  class RepresentDownstream
    def call(content_ids, with_drafts: true)
      if with_drafts
        found_content_ids = Queries::FindContentIdsOnStore.call(content_ids, %w[draft live])
        found_content_ids.each do |content_id|
          downstream_draft(content_id)
        end
      end

      found_content_ids = Queries::FindContentIdsOnStore.call(content_ids, %w[live])
      found_content_ids.each do |content_id|
        downstream_live(content_id)
      end
    end

  private

    def downstream_draft(content_id)
      event_payload = {
        content_id:,
        message: "Representing downstream draft",
      }

      EventLogger.log_command(self.class, event_payload) do |_event|
        DownstreamDraftJob.perform_async(
          "content_id" => content_id,
          "update_dependencies" => false,
          "source_command" => "represent_downstream",
        )
      end
    end

    def downstream_live(content_id)
      event_payload = {
        content_id:,
        message: "Representing downstream live",
      }

      EventLogger.log_command(self.class, event_payload) do |_event|
        DownstreamLiveJob.perform_async(
          "content_id" => content_id,
          "message_queue_event_type" => "links",
          "update_dependencies" => false,
          "source_command" => "represent_downstream",
        )
      end
    end
  end
end
