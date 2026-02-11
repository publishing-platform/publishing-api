require "rails_helper"

RSpec.describe RequeueContentJob do
  let(:edition) { create(:live_edition, base_path: "/ci1", schema_name: "generic") }

  it "it republishes the edition with the version" do
    expect(PublishingApi.service(:queue_publisher)).to receive(:send_message).with(
      hash_including(
        title: "VAT rates",
        base_path: "/ci1",
        payload_version: 10,
      ),
      routing_key: "generic.bulk.reindex",
      persistent: false,
    )

    subject.perform("edition_id" => edition.id, "version" => 10)
  end
end
