module Presenters
  class EditionPresenter
    NON_PRESENTED_PROPERTIES = %i[
      api_path
      api_url
      auth_bypass_ids
      content_store
      created_at
      document_id
      id
      last_edited_at
      major_published_at
      published_at
      publishing_request_id
      state
      unpublishing_type
      updated_at
      user_facing_version
      web_url
      withdrawn
    ].freeze

    def initialize(edition, draft: false)
      @edition = edition
      @draft = draft
    end

    def for_content_store(payload_version)
      present.except(:update_type).merge(payload_version:)
    end

    def present
      edition.to_h
        .except(*NON_PRESENTED_PROPERTIES)
        .merge(auth_bypass_ids)
        .merge(rendered_details)
        # .merge(expanded_links_attributes)
        .merge(schema_name_and_document_type)
        # .merge(document_supertypes)
        # .merge(withdrawal_notice)
        # .merge(publishing_request_id)
    end

    # def expanded_links
    #   expanded_link_set_presenter.links
    # end

    def rendered_details
      { details: details_presenter.details }
    end

  private

    attr_reader :draft, :edition

    def auth_bypass_ids
      return {} unless draft

      { auth_bypass_ids: edition.auth_bypass_ids || [] }
    end

    # def unexpanded_links
    #   links = ::Queries::LinksForEditionIds.new([edition.id]).merged_links
    #   links[edition.id].symbolize_keys
    # end

    # def expanded_links_attributes
    #   {
    #     expanded_links:,
    #   }
    # end

    # def expanded_link_set_presenter
    #   @expanded_link_set_presenter ||= Presenters::Queries::ExpandedLinkSet.by_edition(
    #     edition,
    #     with_drafts: draft,
    #   )
    # end

    def details_presenter
      @details_presenter ||= Presenters::DetailsPresenter.new(
        edition.to_h[:details],
        change_history_presenter,
      )
    end

    def change_history_presenter
      @change_history_presenter ||=
        Presenters::ChangeHistoryPresenter.new(edition)
    end

    def schema_name_and_document_type
      {
        schema_name: edition.schema_name,
        document_type: edition.document_type,
      }
    end

    # def document_supertypes
    #   GovukDocumentTypes.supertypes(document_type: edition.document_type)
    # end

    # def withdrawal_notice
    #   unpublishing = edition.unpublishing

    #   if unpublishing && unpublishing.withdrawal?
    #     withdrawn_at = (unpublishing.unpublished_at || unpublishing.created_at).iso8601
    #     {
    #       withdrawn_notice: {
    #         explanation: unpublishing.explanation,
    #         withdrawn_at:,
    #       },
    #     }
    #   else
    #     {}
    #   end
    # end

    # def publishing_request_id
    #   if edition.publishing_request_id
    #     {
    #       publishing_request_id: edition.publishing_request_id,
    #     }
    #   else
    #     {}
    #   end
    # end
  end
end