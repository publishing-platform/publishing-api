class LinkSetsController < ApplicationController
  def get_links
    render json: Queries::GetLinkSet.call(content_id)
  end

private

  def content_id
    params.fetch(:content_id)
  end
end
