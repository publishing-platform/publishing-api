require "rails_helper"

RSpec.describe EventLogger do
  let(:command_class) { Commands::Publish }
  let(:payload) { { stuff: "1234" } }

  before do
    allow(PublishingPlatformApi::PublishingPlatformHeaders).to receive(:headers)
      .and_return(publishing_platform_request_id: "09876-54321")
  end

  it "records an event, given the name and payload" do
    EventLogger.log_command(command_class, payload)
    expect(Event.count).to eq(1)
    expect(Event.first.action).to eq("Publish")
    expect(Event.first.payload).to eq(payload)
    expect(Event.first.request_id).to eq("09876-54321")
  end

  it "returns the return value of the block" do
    value = EventLogger.log_command(command_class, payload) do
      "yes"
    end
    expect(value).to eq("yes")
  end

  it "does not record an event if the block raises an uncaught exception" do
    expect {
      EventLogger.log_command(command_class, payload) do
        raise "unchecked error"
      end
    }.to raise_error("unchecked error")
    expect(Event.count).to eq(0)
  end

  it "adds the content ID if present" do
    content_id = SecureRandom.uuid

    EventLogger.log_command(command_class, content_id:)
    expect(Event.count).to eq(1)
    expect(Event.last.content_id).to eq(content_id)

    EventLogger.log_command(command_class, {})
    expect(Event.count).to eq(2)
    expect(Event.last.content_id).to be_nil
  end
end
