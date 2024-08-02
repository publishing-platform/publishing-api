class LinkSetsController < ApplicationController
  def get_links
    render json: Queries::GetLinkSet.call(content_id)
  end

  def patch_links
    response = Commands::PatchLinkSet.call(links_params)
    render status: response.code, json: response
  end

private

  def links_params
    payload.merge(content_id:)
  end

  def content_id
    params.fetch(:content_id)
  end
end
