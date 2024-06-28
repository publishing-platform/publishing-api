Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  def content_id_constraint(request)
    UuidValidator.valid?(request.params[:content_id])
  end

  scope format: false do
    scope constraints: method(:content_id_constraint) do
      put "/content/:content_id", to: "content_items#put_content"
      get "/content/:content_id", to: "content_items#show"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
