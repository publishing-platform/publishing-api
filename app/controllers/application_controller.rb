class ApplicationController < ActionController::API
  include PublishingPlatform::SSO::ControllerMethods

  rescue_from CommandError, with: :respond_with_command_error

  before_action :authenticate_user!

  Warden::Manager.after_authentication do |user, _, _|
    user.set_app_name!
  end  

private 

  def respond_with_command_error(error)
    error = error.cause unless error.is_a?(CommandError)
    render status: error.code, json: error
  end

  def payload
    @payload ||= JSON.parse(request.body.read).deep_symbolize_keys
  end  

  def query_params
    @query_params ||= ActionController::Parameters.new(request.query_parameters)
  end

  def path_params
    @path_params ||= ActionController::Parameters.new(request.path_parameters)
  end  
end
