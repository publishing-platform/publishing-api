class ContentItemsController < ApplicationController
  def show
    render json: { hello: "world" }
  end

  def put_content
    response = PutContent.call(edition)
    render status: response.code, json: response
  end

private

  def edition
    payload.merge(content_id: path_params[:content_id])
  end
end
