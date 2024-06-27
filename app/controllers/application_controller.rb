class ApplicationController < ActionController::API
  include PublishingPlatform::SSO::ControllerMethods
end
