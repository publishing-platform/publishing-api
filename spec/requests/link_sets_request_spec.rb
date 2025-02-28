require "rails_helper"

RSpec.describe "/links", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:request_path) { "/links/#{content_id}" }
  let(:patch_links_params) do
    {
      content_id:,
      links: {
        primary_publishing_organisation: %w[30986e26-f504-4e14-a93f-a9593c34a8d9],
      },
    }
  end

  describe "GET /get_links" do
    context "when the document exists" do
      let!(:document) { create(:document, content_id:) }

      context "but no link set exists" do
        it "responds successfully" do
          get request_path

          expect(response.status).to eq(200)
        end

        it "returns default values" do
          get request_path

          expect(parsed_response["content_id"]).to eq(content_id)
          expect(parsed_response["version"]).to eq(0)
          expect(parsed_response["links"]).to eq({})
        end
      end

      context "and links exists" do
        let!(:link_set) do
          create(:link_set, document:, content_id:, stale_lock_version: 5)
        end

        let(:parent) { SecureRandom.uuid }
        let(:related) { [SecureRandom.uuid, SecureRandom.uuid] }

        before do
          create(
            :link,
            link_set:,
            link_type: "parent",
            target_content_id: parent,
          )

          create(
            :link,
            link_set:,
            link_type: "related",
            target_content_id: related.first,
          )

          create(
            :link,
            link_set:,
            link_type: "related",
            target_content_id: related.last,
          )
        end

        it "responds successfully" do
          get request_path

          expect(response.status).to eq(200)
        end

        it "returns links" do
          get request_path

          expect(parsed_response).to match(
            a_hash_including(
              "content_id" => content_id,
              "version" => 5,
              "links" => a_hash_including(
                "parent" => [parent],
                "related" => a_collection_including(related.last, related.first),
              ),
            ),
          )
        end
      end
    end

    context "when the document does not exist" do
      it "responds with status 404" do
        get request_path

        expect(response.status).to eq(404)
      end
    end
  end

  describe "PATCH /patch_links" do
    let!(:document) { create(:document, content_id:) }
    let!(:edition) do
      create(:edition,
             document:,
             base_path:,
             title: "Some Title")
    end
    let(:primary_publishing_organisation) { [SecureRandom.uuid] }
    let(:parent) { [SecureRandom.uuid] }

    let(:payload) do
      {
        content_id:,
        links: {
          primary_publishing_organisation:,
          parent:,
        },
      }
    end

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    context "when no link set exists" do
      it "responds successfully" do
        patch request_path, params: payload.to_json

        expect(response.status).to eq(200)
      end

      it "responds with a success object containing the newly created links in the same order as in the request" do
        patch request_path, params: payload.to_json

        expect(parsed_response.deep_symbolize_keys).to eq(
          content_id:,
          version: 1,
          links: {
            primary_publishing_organisation:,
            parent:,
          },
        )
      end
    end

    context "when link set exists" do
      before do
        create(
          :link_set,
          content_id:,
          stale_lock_version: 1,
          links: [
            create(
              :link,
              link_type: "primary_publishing_organisation",
              target_content_id: primary_publishing_organisation.first,
            ),
          ],
        )
      end

      it "responds successfully" do
        patch request_path, params: payload.to_json

        expect(response.status).to eq(200)
      end

      it "responds with a success object containing any existing links and newly created links" do
        patch request_path, params: payload.to_json

        expect(parsed_response.deep_symbolize_keys).to eq(
          content_id:,
          version: 2,
          links: {
            primary_publishing_organisation:,
            parent:,
          },
        )
      end

      context "and payload contains an updated link" do
        let(:updated_link) { [SecureRandom.uuid] }
        let(:payload) do
          {
            content_id:,
            links: {
              primary_publishing_organisation: updated_link,
            },
          }
        end

        it "responds successfully" do
          patch request_path, params: payload.to_json

          expect(response.status).to eq(200)
        end

        it "responds with a success object containing any updated links" do
          patch request_path, params: payload.to_json

          expect(parsed_response.deep_symbolize_keys).to eq(
            content_id:,
            version: 2,
            links: {
              primary_publishing_organisation: updated_link,
            },
          )
        end
      end

      context "and no links are provided in the payload" do
        let(:payload) do
          {
            content_id:,
            links: {},
          }
        end

        it "responds successfully" do
          patch request_path, params: payload.to_json

          expect(response.status).to eq(200)
        end

        it "responds with a success object containing existing links" do
          patch request_path, params: payload.to_json

          expect(parsed_response.deep_symbolize_keys).to eq(
            content_id:,
            version: 2,
            links: {
              primary_publishing_organisation:,
            },
          )
        end
      end

      context "and previous_version conflicts" do
        let(:payload) do
          {
            content_id:,
            links: {
              primary_publishing_organisation:,
              parent:,
            },
            previous_version: 2,
          }
        end

        it "responds with status 409 (Conflict) and appropriate error message" do
          patch request_path, params: payload.to_json

          expect(response.status).to eq(409)
          expect(parsed_response["error"]["message"]).to match "A lock-version conflict occurred"
        end
      end
    end

    context "when only a draft edition exists for the link set" do
      it "only sends to the draft content store" do
        allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item).with(anything)
        expect(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
        expect(PublishingApi.service(:live_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /[^-]content-store.*/)

        patch request_path, params: payload.to_json

        expect(response.status).to eq(200)
      end
    end

    context "when only a live edition exists for the link set" do
      before do
        edition.publish
      end

      it "sends the live item to both content stores" do
        allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item).with(anything)
        allow(PublishingApi.service(:live_content_store)).to receive(:put_content_item).with(anything)

        expect(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
        expect(PublishingApi.service(:live_content_store)).to receive(:put_content_item)

        patch request_path, params: payload.to_json

        expect(response.status).to eq(200)
      end
    end

    context "when draft and live editions exists for the link set" do
      let!(:edition) do
        create(:live_edition,
               :with_draft,
               document:,
               base_path:,
               title: "Some Title")
      end

      it "sends to both content stores" do
        allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item).with(anything)
        allow(PublishingApi.service(:live_content_store)).to receive(:put_content_item).with(anything)

        expect(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
        expect(PublishingApi.service(:live_content_store)).to receive(:put_content_item)

        patch request_path, params: payload.to_json

        expect(response.status).to eq(200)
      end
    end

    context "when payload is invalid" do
      let(:payload) do
        {
          content_id:,
          links: [],
        }
      end

      it "responds with status 422 and appropriate error message" do
        patch request_path, params: payload.to_json

        expect(response.status).to eq(422)
        expect(parsed_response["error"]["message"]).to eq "Links are required"
      end
    end

    context "when document doesn't exist" do
      before do
        Edition.delete_all
        Document.delete_all
      end
      it "responds with status 422 and appropriate error message" do
        patch request_path, params: payload.to_json

        expect(response.status).to eq(422)
        expect(parsed_response.first).to eq "Schema could not be validated as the schema_name was not provided"
      end
    end

    context "when an edition does not exist for the link set" do
      before do
        Edition.delete_all
      end

      it "does not send to either content store" do
        expect(WebMock).not_to have_requested(:any, /.*content-store.*/)
        expect(PublishingApi.service(:draft_content_store)).not_to receive(:put_content_item)
        expect(PublishingApi.service(:live_content_store)).not_to receive(:put_content_item)

        patch request_path, params: payload.to_json

        expect(response.status).to eq(422)
      end
    end

    context "when payload does not conform to schema" do
      let(:payload) do
        {
          content_id:,
          links: {
            primary_publishing_organisation:,
            parent:,
            not_in_schema: [SecureRandom.uuid],
          },
        }
      end
      it "responds with status 422 and appropriate error message" do
        patch request_path, params: payload.to_json

        expect(response.status).to eq(422)
        expect(parsed_response.first["message"]).to match "The property '#/links' contains additional properties"
      end
    end

    context "draft content store times out" do
      before do
        stub_request(:put, PublishingPlatformLocation.find("draft-content-store") + "/content#{base_path}").to_timeout
      end

      it "returns an error" do
        patch request_path, params: patch_links_params.to_json

        expect(response.status).to eq(500)
        expect(parsed_response).to eq(
          "error" => {
            "code" => 500,
            "message" => "Unexpected error from the downstream application: Timed out connecting to server",
          },
        )
      end
    end

    context "content store times out" do
      before do
        edition.publish
        stub_request(:put, PublishingPlatformLocation.find("content-store") + "/content#{base_path}").to_timeout
      end

      it "returns an error" do
        patch request_path, params: patch_links_params.to_json

        expect(response.status).to eq(500)
        expect(parsed_response).to eq(
          "error" => {
            "code" => 500,
            "message" => "Unexpected error from the downstream application: Timed out connecting to server",
          },
        )
      end
    end
  end
end
