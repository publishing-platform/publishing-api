class ContentItemsController < ApplicationController
  def show
    render json: { hello: "world" }
  end

  def put_content
    response = Commands::PutContent.call(edition)
    render status: response.code, json: response
  end

  def publish
    response = Commands::Publish.call(edition)
    render status: response.code, json: response
  end  

private

  def edition
    payload.merge(content_id: path_params[:content_id])
  end
end
