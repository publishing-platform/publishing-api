module EventLogger
  def self.log_command(command_class, payload, &_block)
    response = nil

    Event.connection.transaction do
      event = Event.create!(
        content_id: payload[:content_id],
        action: command_class.name,
        payload:,
        user_uid: PublishingPlatformApi::PublishingPlatformHeaders.headers[:x_publishing_platform_authenticated_user],
        request_id: PublishingPlatformApi::PublishingPlatformHeaders.headers[:publishing_platform_request_id],
      )
      response = yield(event) if block_given?
    end

    response
  end
end
