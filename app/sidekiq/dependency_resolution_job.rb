class DependencyResolutionJob
  include Sidekiq::Job

  QUEUE = "dependency_resolution".freeze

  sidekiq_options queue: QUEUE

  def perform(args = {})
    # Do something
    logger.debug "DependencyResolutionJob executing..."
    logger.debug { "args: #{args.inspect}" }

    assign_attributes(args)

    dependencies.each do |content_id|
      send_downstream(content_id)
    end

    orphaned_content_ids_for_content_store.each { |content_id| send_downstream(content_id) }
  end

private

  attr_reader :content_id,
              :content_store,
              :orphaned_content_ids,
              :source_command,
              :source_document_type,
              :source_fields

  def assign_attributes(args)
    @content_id = args.fetch("content_id")
    @content_store = args.fetch("content_store").constantize
    @orphaned_content_ids = args.fetch("orphaned_content_ids", [])
    @source_command = args["source_command"]
    @source_document_type = args["source_document_type"]
    @source_fields = args.fetch("source_fields", [])
  end

  def orphaned_content_ids_for_content_store
    Document
      .distinct
      .joins(:editions)
      .where(editions: { content_store: content_stores },
             content_id: orphaned_content_ids)
      .pluck(:content_id)
  end

  def content_stores
    draft? ? %w[draft live] : %w[live]
  end

  def dependencies
    Queries::ContentDependencies.new(
      content_id:,
      content_stores:,
    ).call
  end

  def draft?
    content_store == Adapters::DraftContentStore
  end

  def send_downstream(content_id)
    downstream_draft(content_id)
    downstream_live(content_id)
  end

  def downstream_draft(dependent_content_id)
    return unless draft?

    DownstreamDraftJob.perform_async(
      worker_params.merge({
        "content_id" => dependent_content_id,
      }),
    )
  end

  def downstream_live(dependent_content_id)
    return if draft?

    DownstreamLiveJob.perform_async(
      worker_params.merge({
        "content_id" => dependent_content_id,
      }),
    )
  end

  def worker_params
    {
      "update_dependencies" => false,
      "dependency_resolution_source_content_id" => content_id,
      "source_command" => source_command,
      "source_fields" => source_fields,
    }
  end
end
