require "rails_helper"

RSpec.describe "Unpublishing editions" do
  let(:put_content_command) { Commands::PutContent }
  let(:publish_command) { Commands::Publish }
  let(:unpublish_command) { Commands::Unpublish }

  let(:content_id) { SecureRandom.uuid }

  let(:put_content_payload) do
    {
      content_id:,
      base_path: "/vat-rates",
      title: "Some Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      document_type: "answer",
      schema_name: "answer",
      details: {},
      routes: [{ path: "/vat-rates", type: "exact" }],
      phase: "beta",
      update_type: "minor",
    }
  end

  let(:publish_payload) do
    {
      content_id:,
    }
  end

  let(:unpublish_payload) do
    {
      content_id:,
      type: "gone",
    }
  end

  before do
    stub_request(:any, /content-store/)
  end

  describe "after the first unpublishing" do
    before do
      put_content_command.call(put_content_payload)
      publish_command.call(publish_payload)
      unpublish_command.call(unpublish_payload)
    end

    it "unpublishes the edition" do
      editions = Edition.with_document.where("documents.content_id": content_id)
      expect(editions.count).to eq(1)

      unpublished_item = editions.last
      expect(unpublished_item.state).to eq("unpublished")
    end

    describe "after the second unpublishing" do
      before do
        put_content_command.call(put_content_payload)
        publish_command.call(publish_payload)
        unpublish_command.call(unpublish_payload)
      end

      it "unpublishes the new edition and supersedes the old edition" do
        editions = Edition.joins(:document)
          .where("documents.content_id": content_id)
        expect(editions.count).to eq(2)

        superseded_item = editions.first
        unpublished_item = editions.last

        expect(superseded_item.state).to eq("superseded")
        expect(unpublished_item.state).to eq("unpublished")
      end
    end
  end
end
