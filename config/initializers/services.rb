require "content_store_writer"

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

if Rails.env.development?
  PublishingApi.swallow_connection_errors = true
end