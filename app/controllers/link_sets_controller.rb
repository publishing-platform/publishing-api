class LinkSetsController < ApplicationController
  def get_links
    render json: Queries::GetLinkSet.call(content_id)
  end

  def patch_links
    response = Commands::PatchLinkSet.call(links_params)
    render status: response.code, json: response
  end

  def expanded_links
    json = Queries::GetExpandedLinks.call(
      content_id,
      with_drafts: with_drafts?,
      generate: generate?,
    )

    render json:
  end

private

  def with_drafts?
    # Cast the `with_drafts` query param to a real boolean, and default to
    # `true` to preserve existing behaviour
    ActiveModel::Type::Boolean.new.cast(params.fetch(:with_drafts, true))
  end

  def generate?
    ActiveModel::Type::Boolean.new.cast(params.fetch(:generate, false))
  end

  def links_params
    payload.merge(content_id:)
  end

  def content_id
    params.fetch(:content_id)
  end
end
