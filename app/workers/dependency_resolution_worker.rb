class DependencyResolutionWorker
  include Sidekiq::Worker

  QUEUE = "dependency_resolution".freeze

  sidekiq_options queue: QUEUE

  def perform(args = {})
    # Do something
    logger.info "DependencyResolutionWorker executing..."
    logger.debug { "args: #{args.inspect}" }
  end
end
