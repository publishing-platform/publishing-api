Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  def content_id_constraint(request)
    UuidValidator.valid?(request.params[:content_id])
  end

  scope format: false do
    put "/paths(/*base_path)", to: "path_reservations#reserve_path"
    delete "/paths(/*base_path)", to: "path_reservations#unreserve_path"

    get "/content", to: "content_items#index"
    scope constraints: method(:content_id_constraint) do
      put "/content/:content_id", to: "content_items#put_content"
      get "/content/:content_id", to: "content_items#show"
      post "/content/:content_id/publish", to: "content_items#publish"
      post "/content/:content_id/republish", to: "content_items#republish"
      post "/content/:content_id/unpublish", to: "content_items#unpublish"
      post "/content/:content_id/discard-draft", to: "content_items#discard_draft"

      get "/links/:content_id", to: "link_sets#get_links"
    end

    get "/linkables", to: "content_items#linkables"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
