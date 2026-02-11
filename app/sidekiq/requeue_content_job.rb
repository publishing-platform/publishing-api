class RequeueContentJob
  include Sidekiq::Job

  QUEUE = "import".freeze

  sidekiq_options queue: QUEUE

  def perform(args = {})
    # Do something
    logger.debug "RequeueContentJob executing..."
    logger.debug { "args: #{args.inspect}" }

    assign_attributes(args)

    edition = Edition.find(edition_id)
    presenter = DownstreamPayload.new(edition, version, draft: false)
    queue_payload = presenter.message_queue_payload
    service = PublishingApi.service(:queue_publisher)

    # Requeue is considered a different event_type to major, minor etc
    # because we don't want to send additional email alerts to users.
    service.send_message(
      queue_payload,
      routing_key: "#{edition.schema_name}.#{action}",
      persistent: false,
    )
  end

private

  attr_reader :edition_id,
              :version,
              :action

  def assign_attributes(args)
    @edition_id = args.fetch("edition_id")
    @version = args.fetch("version")
    @action = args.fetch("action", "bulk.reindex")
  end
end
