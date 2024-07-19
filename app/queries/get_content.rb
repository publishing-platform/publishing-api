module Queries
  module GetContent
    def self.call(content_id, version: nil, include_warnings: false)
      editions = Edition.with_document
        .where(documents: { content_id: })

      editions = editions.where(user_facing_version: version) if version

      response = Presenters::Queries::ContentItemPresenter.present_many(
        editions,
        include_warnings:,
        states: %i[draft published unpublished superseded],
      ).first

      if response.present?
        response
      else
        message = not_found_message(content_id, version)
        raise_not_found(message)
      end
    end

    def self.raise_not_found(message)
      raise CommandError.new(code: 404, message:)
    end

    def self.not_found_message(content_id, version)
      if Document.exists?(content_id:)
        "Could not find version: #{version} for document with content_id: #{content_id}"
      else
        "Could not find document with content_id: #{content_id}"
      end
    end
    private_class_method :raise_not_found, :not_found_message
  end
end