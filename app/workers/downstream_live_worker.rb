require "sidekiq-unique-jobs"

class DownstreamLiveWorker
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
    logger.info "DownstreamLiveWorker executing..."
    logger.debug { "args: #{args.inspect}" }
  end
end
