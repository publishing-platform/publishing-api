class Presenters::GonePresenter
  def initialize(base_path:, content_id:, publishing_app:, public_updated_at:, alternative_path:, explanation:, routes:)
    @base_path = base_path
    @content_id = content_id
    @publishing_app = publishing_app
    @public_updated_at = public_updated_at
    @alternative_path = alternative_path
    @explanation = explanation
    @routes = routes
  end

  def self.from_edition(edition)
    new(
      base_path: edition.base_path,
      content_id: edition.content_id,
      publishing_app: edition.publishing_app,
      public_updated_at: edition.unpublishing.unpublished_at || edition.unpublishing.created_at,
      alternative_path: edition.unpublishing.alternative_path,
      explanation: edition.unpublishing.explanation,
      routes: edition.routes,
    )
  end

  def for_content_store(payload_version)
    present.merge(payload_version:)
  end

  def for_message_queue(payload_version)
    present.merge(
      content_id:,
      publishing_platform_request_id: PublishingPlatformApi::PublishingPlatformHeaders.headers[:publishing_platform_request_id],
      payload_version:,
    )
  end

private

  attr_reader :base_path, :content_id, :publishing_app, :public_updated_at, :alternative_path, :explanation, :routes

  def present
    {
      document_type: "gone",
      schema_name: "gone",
      base_path:,
      publishing_app:,
      public_updated_at: public_updated_at&.iso8601,
      details: {
        explanation:,
        alternative_path:,
      },
      routes:,
    }
  end
end
