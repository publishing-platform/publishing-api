class ApplicationController < ActionController::API
  include PublishingPlatform::SSO::ControllerMethods

  before_action :authenticate_user!

  Warden::Manager.after_authentication do |user, _, _|
    user.set_app_name!
  end  
end
