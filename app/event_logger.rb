module EventLogger
  def self.log_command(command_class, payload, &_block)
    response = nil

    Event.connection.transaction do
      event = Event.create!(
        content_id: payload[:content_id],
        action: action(command_class),
        payload:,
        user_uid: PublishingPlatformApi::PublishingPlatformHeaders.headers[:x_publishing_platform_authenticated_user],
        request_id: PublishingPlatformApi::PublishingPlatformHeaders.headers[:publishing_platform_request_id],
      )
      response = yield(event) if block_given?
    end

    response
  end

  def self.action(command_class)
    command_class.name.split("::")[-1]
  end
  private_class_method :action  
end
