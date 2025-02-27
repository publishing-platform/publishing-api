require "rails_helper"

RSpec.describe "/content", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:validator) do
    instance_double(SchemaValidator, valid?: true, errors: [])
  end

  before do
    allow(SchemaValidator).to receive(:new).and_return(validator)
    stub_request(:any, /content-store/)
  end

  describe "GET /index" do
    let(:previous_edition) do
      create(
        :superseded_edition,
        base_path: "/foo",
        title: "zip",
        user_facing_version: 1,
      )
    end
    let!(:edition) do
      create(
        :live_edition,
        base_path: "/foo",
        document: previous_edition.document,
        title: "bar",
        description: "stuff",
        user_facing_version: 2,
      )
    end

    context "searching a field" do
      context "when there is a valid query" do
        it "returns the item when searching for base_path" do
          get "/content", params: { q: "foo" }

          expect(response.status).to eq(200)
          expect(parsed_response["results"].count).to eq(1)
          expect(parsed_response["total"]).to eq(1)
          expect(parsed_response["pages"]).to eq(1)
          expect(parsed_response["current_page"]).to eq(1)
          expect(parsed_response["results"][0]["base_path"]).to eq("/foo")
        end

        it "returns the item when searching for title" do
          get "/content", params: { q: "bar" }

          expect(response.status).to eq(200)
          expect(parsed_response["results"].count).to eq(1)
          expect(parsed_response["total"]).to eq(1)
          expect(parsed_response["pages"]).to eq(1)
          expect(parsed_response["current_page"]).to eq(1)
          expect(parsed_response["results"][0]["base_path"]).to eq("/foo")
        end

        it "doesn't return items that are no longer the latest version" do
          get "/content", params: { q: "zip" }
          expect(response.status).to eq(200)
          expect(parsed_response["results"].count).to eq(0)
        end
      end

      context "specifying fields to search" do
        it "returns the item" do
          get "/content", params: { q: "stuff", search_in: %w[description] }

          expect(response.status).to eq(200)
          expect(parsed_response["results"][0]["base_path"]).to eq("/foo")
        end
      end
    end

    context "with a document_type param" do
      let!(:other_edition) do
        create(
          :live_edition,
          document_type: "organisation",
        )
      end

      it "filters by document type" do
        get "/content", params: { document_type: "answer" }

        expect(response.status).to eq(200)
        expect(parsed_response["results"].count).to eq(1)
        expect(parsed_response["results"][0]["base_path"]).to eq("/foo")
      end
    end

    context "with pagination params" do
      it "responds with the edition" do
        get "/content", params: { start: "0", page_size: "20" }

        expect(response.status).to eq(200)
        expect(parsed_response["results"].count).to eq(1)
        expect(parsed_response["results"][0]["base_path"]).to eq("/foo")
      end
    end

    context "with an order param" do
      let!(:other_edition) { create(:live_edition, base_path: "/bar") }

      before do
        edition.update!(
          updated_at: Date.new(2016, 1, 1),
          last_edited_at: Date.new(2016, 1, 1),
        )

        other_edition.update!(
          updated_at: Date.new(2016, 2, 2),
          last_edited_at: Date.new(2016, 2, 2),
        )

        get "/content", params: { order:, fields: }
      end

      context "when ordering by updated_at ascending" do
        let(:order) { "updated_at" }
        let(:fields) { %w[updated_at] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "updated_at" => "2016-01-01T00:00:00Z" },
            { "updated_at" => "2016-02-02T00:00:00Z" },
          ])
        end
      end

      context "when ordering by updated_at descending" do
        let(:order) { "-updated_at" }
        let(:fields) { %w[updated_at] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "updated_at" => "2016-02-02T00:00:00Z" },
            { "updated_at" => "2016-01-01T00:00:00Z" },
          ])
        end
      end

      context "when ordering by last_edited_at ascending" do
        let(:order) { "last_edited_at" }
        let(:fields) { %w[last_edited_at] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "last_edited_at" => "2016-01-01T00:00:00Z" },
            { "last_edited_at" => "2016-02-02T00:00:00Z" },
          ])
        end
      end

      context "when ordering by last_edited_at descending" do
        let(:order) { "-last_edited_at" }
        let(:fields) { %w[last_edited_at] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "last_edited_at" => "2016-02-02T00:00:00Z" },
            { "last_edited_at" => "2016-01-01T00:00:00Z" },
          ])
        end
      end

      context "when ordering by base_path ascending" do
        let(:order) { "base_path" }
        let(:fields) { %w[base_path] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "base_path" => "/bar" },
            { "base_path" => "/foo" },
          ])
        end
      end

      context "when ordering by base_path descending" do
        let(:order) { "-base_path" }
        let(:fields) { %w[base_path] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "base_path" => "/foo" },
            { "base_path" => "/bar" },
          ])
        end
      end

      context "when ordering by a field that doesn't exist" do
        let(:order) { "doesnt_exist" }
        let(:fields) { %w[content_id] }

        it "responds with 422 and an error message" do
          expect(response.status).to eq(422)
          message = parsed_response["error"]["message"]
          expect(message).to include(order)
        end
      end

      context "when ordering by a field without an index" do
        let(:order) { "created_at" }
        let(:fields) { %w[content_id] }

        it "responds with 422 and an error message" do
          expect(response.status).to eq(422)
          message = parsed_response["error"]["message"]
          expect(message).to include(order)
        end
      end

      context "ordering by updated_at when it's not selected" do
        let(:order) { "updated_at" }
        let(:fields) { %w[base_path] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "base_path" => "/foo" },
            { "base_path" => "/bar" },
          ])
        end
      end
    end

    context "with a publishing_app param" do
      let!(:other_edition) do
        create(
          :draft_edition,
          publishing_app: "organisations-publisher",
        )
      end

      it "filters by publishing app" do
        get "/content", params: { publishing_app: "organisations-publisher" }

        expect(response.status).to eq(200)
        expect(parsed_response["results"].count).to eq(1)
        expect(parsed_response["results"].all? { |i| i["publishing_app"] == "organisations-publisher" }).to be true
      end
    end

    context "with a state param" do
      let!(:other_edition) { create(:draft_edition) }

      it "filters by state" do
        get "/content", params: { states: %w[superseded] }

        expect(response.status).to eq(200)
        expect(parsed_response["results"].count).to eq(1)
        expect(parsed_response["results"][0]["content_id"]).to eq(edition.content_id)
      end
    end

    context "with link filtering params" do
      let(:document) { create(:document, content_id:) }
      let!(:edition) do
        create(
          :live_edition,
          base_path: "/foo",
          document:,
        )
      end

      before do
        org_content_id = SecureRandom.uuid
        link_set = create(:link_set, content_id:)
        create(:link, link_set:, target_content_id: org_content_id)

        get "/content", params: { fields: %w[content_id], link_primary_publishing_organisation: org_content_id }
      end

      it "responds with the editions for the given primary publishing organistion" do
        expect(response.status).to eq(200)
        expect(parsed_response["results"].count).to eq(1)
        expect(parsed_response["results"].first.fetch("content_id")).to eq(content_id)
      end
    end
  end

  describe "GET /show" do
    context "for an existing edition" do
      let!(:document) { create(:document, content_id:) }
      let!(:edition) { create(:edition, document:) }
      let(:request_path) { "/content/#{content_id}" }

      it "responds with the edition" do
        get request_path

        expect(response.status).to eq(200)
        expect(parsed_response["content_id"]).to eq(content_id)
      end

      context "with edition links" do
        let(:target_content_id) { SecureRandom.uuid }

        before do
          edition.links.create!(
            link_type: "primary_publishing_organisation",
            target_content_id:,
          )
        end

        it "includes the edition links in the JSON" do
          get request_path

          expect(response.status).to eq(200)
          expect(parsed_response["links"]["primary_publishing_organisation"]).to_not be_empty
          expect(parsed_response["links"]["primary_publishing_organisation"]).to match_array([target_content_id])
        end
      end
    end

    context "for a non-existent edition" do
      let(:request_path) { "/content/#{SecureRandom.uuid}" }

      it "responds with 404" do
        get request_path

        expect(response.status).to eq(404)
      end
    end
  end

  describe "PUT /put_content" do
    let(:request_path) { "/content/#{content_id}" }

    context "with valid request params for a new edition" do
      before do
        put request_path, params: content_item_params.to_json
      end

      it "responds with 200" do
        expect(response.status).to eq(200)
      end

      it "responds with the new edition" do
        new_edition = Edition.with_document.find_by!("documents.content_id": content_id)
        presented_content_item = Presenters::Queries::ContentItemPresenter.present(
          new_edition,
          include_warnings: true,
        )

        expect(response.body).to eq(presented_content_item.to_json)
      end
    end

    context "with valid request params for an existing edition" do
      let(:edition) { create(:edition) }
      let(:content_id) { edition.document.content_id }

      before do
        put request_path, params: content_item_params.to_json
      end

      it "responds with 200" do
        expect(response.status).to eq(200)
      end

      it "responds with the updated edition" do
        updated_edition = Edition.with_document.find_by!("documents.content_id": content_id)
        presented_content_item = Presenters::Queries::ContentItemPresenter.present(
          updated_edition,
          include_warnings: true,
        )

        expect(response.body).to eq(presented_content_item.to_json)
      end
    end

    context "with invalid json" do
      it "responds with 400" do
        put request_path, params: "Not JSON"
        expect(response.status).to eq(400)
      end
    end

    context "when draft content store is not running but draft 502s are suppressed" do
      before do
        @swallow_connection_errors = PublishingApi.swallow_connection_errors
        PublishingApi.swallow_connection_errors = true
        stub_request(:put, %r{^http://draft-content-store.*/content/.*})
          .to_return(status: 502)
      end

      after do
        PublishingApi.swallow_connection_errors = @swallow_connection_errors
      end

      it "returns the normal 200 response" do
        put request_path, params: content_item_params.to_json

        parsed_response
        expect(response.status).to eq(200)
        expect(parsed_response["content_id"]).to eq(content_id)
        expect(parsed_response["title"]).to eq(content_item_params[:title])
      end
    end

    context "when draft content store times out" do
      before do
        stub_request(:put, PublishingPlatformLocation.find("draft-content-store") + "/content#{base_path}").to_timeout
      end

      it "returns an appropriate error" do
        put request_path, params: content_item_params.to_json

        expect(response.status).to eq(500)
        expect(parsed_response).to eq(
          "error" => {
            "code" => 500,
            "message" => "Unexpected error from the downstream application: Timed out connecting to server",
          },
        )
      end
    end

    it "reserves path" do
      put request_path, params: content_item_params.to_json

      expect(PathReservation.count).to eq(1)
      expect(PathReservation.first.base_path).to eq(content_item_params[:base_path])
      expect(PathReservation.first.publishing_app).to eq(content_item_params[:publishing_app])
    end

    context "when a base path is occupied by a 'regular' edition" do
      before do
        create(
          :draft_edition,
          base_path:,
        )
      end

      it "cannot be replaced by another draft 'regular' edition" do
        put request_path, params: content_item_params.to_json

        expect(response.status).to eq(422)
      end
    end

    context "when a base path is occupied by a published 'regular' edition" do
      before do
        create(
          :live_edition,
          base_path:,
        )
      end

      it "can be replaced by another 'regular' edition" do
        put request_path, params: content_item_params.to_json

        expect(response.status).to eq(200)
      end
    end
  end
end
