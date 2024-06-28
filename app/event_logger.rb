module EventLogger
  def self.log_command(command_class, payload, &_block)
    response = nil

    Event.connection.transaction do
      event = Event.create!(
        content_id: payload[:content_id],
        action: command_class.name,
        payload:,
        # TODO
        # user_uid: GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user],
        # request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
      )
      response = yield(event) if block_given?
    end

    response
  end
end