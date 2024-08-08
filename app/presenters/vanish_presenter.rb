class Presenters::VanishPresenter
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

  def for_content_store(payload_version)
    present.merge(payload_version:)
  end

private

  attr_reader :base_path, :publishing_app, :content_id

  def present
    {
      document_type: "vanish",
      schema_name: "vanish",
      base_path:,
      publishing_app:,
    }
  end
end