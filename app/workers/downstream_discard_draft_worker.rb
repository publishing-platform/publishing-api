class DownstreamDiscardDraftWorker
  include Sidekiq::Worker

  QUEUE = "downstream".freeze

  sidekiq_options queue: QUEUE

  def perform(args = {})
    # Do something
    logger.info "DownstreamDiscardDraftWorker executing..."
    logger.debug { "args: #{args.inspect}" }
  end
end
