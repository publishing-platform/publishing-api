require "content_store_writer"
require "queue_publisher"

module PublishingApi
  # To be set in dev mode so that this can run when the draft content store isn't running.
  cattr_accessor :swallow_connection_errors

  def self.register_service(name:, client:)
    @services ||= {}

    @services[name] = client
  end

  def self.service(name)
    @services[name] || raise(ServiceNotRegisteredException, name)
  end

  class ServiceNotRegisteredException < RuntimeError; end
end

PublishingApi.register_service(
  name: :draft_content_store,
  client: ContentStoreWriter.new(
    PublishingPlatformLocation.find("draft-content-store"),
    bearer_token: ENV["DRAFT_CONTENT_STORE_BEARER_TOKEN"],
  ),
)

PublishingApi.register_service(
  name: :live_content_store,
  client: ContentStoreWriter.new(
    PublishingPlatformLocation.find("content-store"),
    bearer_token: ENV["CONTENT_STORE_BEARER_TOKEN"],
  ),
)

rabbitmq_config = if ENV["DISABLE_QUEUE_PUBLISHER"] || (Rails.env.test? && ENV["ENABLE_QUEUE_IN_TEST_MODE"].blank?)
                    { noop: true }
                  elsif ENV["RABBITMQ_URL"]
                    { exchange: ENV.fetch("RABBITMQ_EXCHANGE", "published_documents") }
                  else
                    Rails.application.config_for(:rabbitmq).symbolize_keys
                  end

PublishingApi.register_service(
  name: :queue_publisher,
  client: QueuePublisher.new(rabbitmq_config),
)

if Rails.env.development?
  PublishingApi.swallow_connection_errors = true
end
