require "rails_helper"

RSpec.describe "Reinstating editions that were previously unpublished" do
  let(:put_content_command) { Commands::PutContent }
  let(:publish_command) { Commands::Publish }

  let(:answer_draft_payload) do
    {
      content_id: SecureRandom.uuid,
      base_path: "/vat-rates",
      title: "Answer Title",
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

  let(:answer_publish_payload) do
    {
      content_id: answer_draft_payload.fetch(:content_id),
    }
  end

  let(:redirect_draft_payload) do
    {
      content_id: SecureRandom.uuid,
      base_path: "/vat-rates",
      publishing_app: "publisher",
      document_type: "redirect",
      schema_name: "redirect",
      redirects: [{ path: "/vat-rates", type: "exact", destination: "/somewhere" }],
      phase: "beta",
      update_type: "minor",
    }
  end

  let(:redirect_publish_payload) do
    {
      content_id: redirect_draft_payload.fetch(:content_id),
    }
  end

  before do
    stub_request(:any, /content-store/)
  end

  describe "after the edition is unpublished" do
    before do
      2.times do
        put_content_command.call(answer_draft_payload)
        publish_command.call(answer_publish_payload)
      end

      put_content_command.call(redirect_draft_payload)
      publish_command.call(redirect_publish_payload)
    end

    it "puts the editions into the correct states and versions" do
      expect(Edition.count).to eq(3)

      superseded1_item = Edition.first
      superseded2_item = Edition.second
      published_item = Edition.third

      expect(superseded1_item.state).to eq("superseded")
      expect(superseded2_item.state).to eq("unpublished")
      expect(published_item.state).to eq("published")

      expect(superseded1_item.user_facing_version).to eq(1)
      expect(superseded2_item.user_facing_version).to eq(2)
      expect(published_item.user_facing_version).to eq(1),
                                                    "The redirect should be regarded as a new piece of content"
    end

    describe "after the original edition has been reinstated" do
      before do
        put_content_command.call(answer_draft_payload)
        publish_command.call(answer_publish_payload)
      end

      it "puts the editions into the correct states and versions" do
        expect(Edition.count).to eq(4)

        superseded1_item = Edition.first
        superseded2_item = Edition.second
        unpublished_item = Edition.third
        published_item = Edition.fourth

        expect(superseded1_item.state).to eq("superseded")
        expect(superseded2_item.state).to eq("superseded")
        expect(unpublished_item.state).to eq("unpublished")
        expect(published_item.state).to eq("published")

        expect(superseded1_item.user_facing_version).to eq(1)
        expect(superseded2_item.user_facing_version).to eq(2)
        expect(unpublished_item.user_facing_version).to eq(1)
        expect(published_item.user_facing_version).to eq(3)
      end

      describe "after the original edition has been superseded (again)" do
        before do
          put_content_command.call(answer_draft_payload)
          publish_command.call(answer_publish_payload)
        end

        it "puts the editions into the correct states and versions" do
          expect(Edition.count).to eq(5)

          superseded1_item = Edition.first
          superseded2_item = Edition.second
          unpublished_item = Edition.third
          superseded3_item = Edition.fourth
          published_item = Edition.fifth

          expect(superseded1_item.state).to eq("superseded")
          expect(superseded2_item.state).to eq("superseded")
          expect(unpublished_item.state).to eq("unpublished")
          expect(superseded3_item.state).to eq("superseded")
          expect(published_item.state).to eq("published")

          expect(superseded1_item.user_facing_version).to eq(1)
          expect(superseded2_item.user_facing_version).to eq(2)
          expect(unpublished_item.user_facing_version).to eq(1)
          expect(superseded3_item.user_facing_version).to eq(3)
          expect(published_item.user_facing_version).to eq(4)
        end
      end
    end
  end
end
