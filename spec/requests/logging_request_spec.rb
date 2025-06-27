require "rails_helper"

RSpec.describe "Logging", type: :request do
  let(:publishing_platform_request_id) { "12345-67890" }

  before do
    stub_request(:any, /content-store/)
  end

  it "adds a request uuid to the content store worker job" do
    Sidekiq::Testing.fake! do
      put(
        "/content/#{SecureRandom.uuid}",
        params: content_item_params.to_json,
        headers: { "HTTP_PUBLISHING_PLATFORM_REQUEST_ID" => publishing_platform_request_id },
      )
      PublishingPlatformApi::PublishingPlatformHeaders.clear_headers # Simulate workers running in a separate thread
      Sidekiq::Job.drain_all # Run all workers
      Sidekiq::Job.clear_all
    end

    expect(WebMock).to have_requested(:put, /draft-content-store.*content/)
      .with(headers: {
        "Publishing-Platform-Request-Id" => publishing_platform_request_id,
      })
  end

  it "adds a request uuid to the message bus" do
    draft_edition = create(:draft_edition, base_path:)

    expect(PublishingApi.service(:queue_publisher)).to receive(:send_message)
      .with(hash_including(publishing_platform_request_id:), event_type: "minor")

    post(
      "/content/#{draft_edition.document.content_id}/publish",
      params: { update_type: "minor" }.to_json,
      headers: { "HTTP_PUBLISHING_PLATFORM_REQUEST_ID" => "12345-67890" },
    )
  end

  context "with Publishing-Platform-Dependency-Resolution-Source-Content-Id" do
    include DependencyResolutionHelper

    let(:a) { create_link_set }
    let(:b) { create_link_set }

    let(:params) do
      content_item_params.merge(
        content_id: a,
        base_path: "/a",
        title: "foo",
        routes: [{ path: "/a", type: "exact" }],
      )
    end

    before do
      create_edition(a, "/a")
      create_edition(b, "/b")
      create_link(a, b, "parent")
    end

    it "is added to the request to the content store" do
      stub_request(:put, /draft-content-store.*content\/(a|b)/)

      Sidekiq::Testing.fake! do
        put("/content/#{a}", params: params.to_json)

        # Simulate workers running in a separate thread
        PublishingPlatformApi::PublishingPlatformHeaders.clear_headers
        # Run all workers
        Sidekiq::Job.drain_all
        Sidekiq::Job.clear_all
      end

      expect(WebMock).to have_requested(:put, /draft-content-store.*content\/b/)
        .with(headers: {
          "Publishing-Platform-Dependency-Resolution-Source-Content-Id" => a,
        })
    end
  end
end
