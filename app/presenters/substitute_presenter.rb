class Presenters::SubstitutePresenter
  def initialize(base_path:, content_id:, publishing_app:)
    @base_path = base_path
    @publishing_app = publishing_app
    @content_id = content_id
  end

  def self.from_edition(edition)
    new(
      base_path: edition.base_path,
      content_id: edition.content_id,
      publishing_app: edition.publishing_app,
    )
  end

  def for_message_queue(payload_version)
    {
      document_type: "substitute",
      schema_name: "substitute",
      base_path: @base_path,
      publishing_app: @publishing_app,
      content_id: @content_id,
      publishing_platform_request_id: PublishingPlatformApi::PublishingPlatformHeaders.headers[:publishing_platform_request_id],
      payload_version:,
    }
  end
end
