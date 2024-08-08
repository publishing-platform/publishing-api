require "sidekiq-unique-jobs"

class DownstreamDraftWorker
  include Sidekiq::Worker

  QUEUE = "downstream".freeze

  sidekiq_options queue: QUEUE,
                  lock: :until_executing,
                  lock_args_method: :uniq_args,
                  on_conflict: :log

  def self.uniq_args(args)
    logger.info args.first
    [
      args.first["content_id"],
      args.first.fetch("update_dependencies", true),
      args.first.fetch("orphaned_content_ids", []),
      name,
    ]
  end

  def perform(args = {})
    # Do something
    logger.info "DownstreamDraftWorker executing..."
    logger.debug { "args: #{args.inspect}" }

    assign_attributes(args)

    unless edition
      raise AbortWorkerError, "A downstreamable edition was not found for content_id: #{content_id}"
    end

    unless dependency_resolution_source_content_id.nil?
      DownstreamService.set_publishing_platform_dependency_resolution_source_content_id_header(
        dependency_resolution_source_content_id,
      )
    end

    DownstreamPayload.new(edition, payload_version, draft: true)
  end

private

  attr_reader :content_id,
              :edition,
              :payload_version,
              :update_dependencies,
              :dependency_resolution_source_content_id,
              :orphaned_content_ids,
              :source_command,
              :source_fields

  def assign_attributes(attributes)
    @content_id = attributes.fetch("content_id")
    @edition = Queries::GetEditionForContentStore.call(content_id, include_draft: true)
    @payload_version = Event.maximum_id
    @orphaned_content_ids = attributes.fetch("orphaned_content_ids", [])
    @update_dependencies = attributes.fetch("update_dependencies", true)
    @dependency_resolution_source_content_id = attributes.fetch(
      "dependency_resolution_source_content_id",
      nil,
    )
    @source_command = attributes["source_command"]
    @source_fields = attributes.fetch("source_fields", [])
  end
end
