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
      before do
        5.times do |n|
          create(
            :draft_edition,
            base_path: "/content-#{n}",
            document_type: "nonexistent-schema",
            schema_name: "nonexistent-schema",
            public_updated_at: n.minutes.ago,
          )
        end

        get "/content", params: { states: %w[draft], offset: "3", per_page: "2" }
      end

      it "responds successfully" do
        expect(response.status).to eq(200)
      end

      it "responds with editions limited by page_size" do
        results = parsed_response["results"]
        expect(results.size).to eq(2)
        expect(results.first["base_path"]).to eq("/content-3")
        expect(results.last["base_path"]).to eq("/content-4")
      end
    end

    context "without an order param" do
      before do
        5.times do |n|
          create(
            :draft_edition,
            base_path: "/content-#{n}",
            document_type: "nonexistent-schema",
            schema_name: "nonexistent-schema",
            public_updated_at: n.minutes.ago,
          )
        end

        get "/content", params: { states: %w[draft] }
      end

      it "responds successfully" do
        expect(response.status).to eq(200)
      end

      it "responds by default with editions ordered by public_updated_at" do
        results = parsed_response["results"]
        expect(results.size).to eq(5)
        expect(results.first["base_path"]).to eq("/content-0")
        expect(results.last["base_path"]).to eq("/content-4")
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
        Timecop.freeze(Time.zone.local(2017, 9, 1, 12, 0, 0))
      end

      after do
        Timecop.return
      end

      subject { Edition.last }

      it "responds with 200" do
        put request_path, params: content_item_params.to_json

        expect(response.status).to eq(200)
      end

      it "responds with the new edition" do
        put request_path, params: content_item_params.to_json

        presented_content_item = Presenters::Queries::ContentItemPresenter.present(
          subject,
          include_warnings: true,
        )

        expect(response.body).to eq(presented_content_item.to_json)
      end

      it "creates an edition" do
        put request_path, params: content_item_params.to_json

        expect(subject).to be_present
        expect(subject.document.content_id).to eq(content_id)
        expect(subject.title).to eq(content_item_params[:title])
      end

      it "sets a draft state for the edition" do
        put request_path, params: content_item_params.to_json
        expect(subject.state).to eq("draft")
      end

      it "sets a user-facing version of 1 for the edition" do
        put request_path, params: content_item_params.to_json
        expect(subject.user_facing_version).to eq(1)
      end

      it "creates a lock version for the edition" do
        put request_path, params: content_item_params.to_json
        expect(subject.document.stale_lock_version).to eq(1)
      end

      it "has a major_published_at of nil" do
        put request_path, params: content_item_params.to_json
        expect(subject.major_published_at).to be_nil
      end

      it "sets last_edited_at to current time" do
        put request_path, params: content_item_params.to_json
        expect(subject.last_edited_at).to eq(Time.zone.now)
      end

      shared_examples "creates a change note" do
        it "creates a change note" do
          expect {
            put request_path, params: payload.to_json
          }.to change { ChangeNote.count }.by(1)
        end
      end

      context "and first_published_at is present in the payload" do
        let(:first_published_at) { Time.zone.now }
        let(:payload) do
          content_item_params.merge({ first_published_at: })
        end

        it "sets first_published_at to first_published_at" do
          put request_path, params: payload.to_json

          expect(subject.first_published_at).to eq(first_published_at)
        end
      end

      context "and the change note is in the payload" do
        let(:change_note) { "change note" }

        let(:payload) do
          content_item_params.merge!({ change_note: })
        end

        include_examples "creates a change note"
      end

      context "and the change history is in the details hash" do
        let(:change_note) { "change note" }

        let(:payload) do
          content_item_params.merge!({
            details: {
              change_history: [
                { note: change_note, public_timestamp: Time.zone.now.utc.rfc3339 },
              ],
            },
          })
        end

        include_examples "creates a change note"
      end

      it "only sends to the draft content store" do
        allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item).with(anything)
        expect(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
        expect(PublishingApi.service(:live_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /[^-]content-store.*/)

        put request_path, params: content_item_params.to_json

        expect(response.status).to eq(200)
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

      it "only sends to the draft content store" do
        allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item).with(anything)
        expect(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
        expect(PublishingApi.service(:live_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /[^-]content-store.*/)

        put request_path, params: content_item_params.to_json

        expect(response.status).to eq(200)
      end
    end

    context "when a link set exists for the edition" do
      let(:document) { create(:document, content_id:) }
      let(:link_set) do
        create(
          :link_set,
          content_id:,
          document:,
        )
      end

      let(:target_edition) { create(:edition, base_path: "/foo", title: "foo") }
      let!(:links) { create(:link, link_set:, link_type: "parent", target_content_id: target_edition.document.content_id) }

      let(:content_item_for_draft_content_store) do
        content_item_params.except(:update_type).merge(
          expanded_links: Presenters::Queries::ExpandedLinkSet.new(content_id:, draft: true).links,
        )
      end

      it "sends to the draft content store" do
        allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item).with(anything)

        put request_path, params: content_item_params.to_json

        expect(PublishingApi.service(:draft_content_store)).to have_received(:put_content_item).twice
        expect(PublishingApi.service(:draft_content_store)).to have_received(:put_content_item)
          .with(a_hash_including(base_path:))
        expect(PublishingApi.service(:draft_content_store)).to have_received(:put_content_item)
          .with(a_hash_including(base_path: target_edition.base_path))

        expect(response.status).to eq(200)
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

    context "when the 'links' parameter is provided" do
      let(:payload) do
        content_item_params.merge!(
          links: {
            a_link_type: [link],
          },
        )
      end

      context "invalid UUID" do
        let!(:link) { "not a UUID" }

        it "should raise a validation error" do
          put request_path, params: payload.to_json

          expect(response.status).to eq(422)
          expect(response.body).to match(/UUID/)
        end
      end

      context "valid UUID" do
        let(:document) { create(:document) }
        let!(:link) { document.content_id }

        it "should create a link" do
          expect {
            put request_path, params: payload.to_json
          }.to change(Link, :count).by(1)

          expect(Link.find_by(target_content_id: document.content_id)).to be
        end
      end

      context "existing links" do
        let(:document) { create(:document, content_id:) }
        let(:link) { SecureRandom.uuid }

        before do
          edition.links.create!(target_content_id: document.content_id, link_type: "a_link_type")
        end

        context "draft edition" do
          let(:edition) { create(:draft_edition, document:, base_path:) }

          it "passes the old link to dependency resolution" do
            expect(DownstreamDraftJob).to receive(:perform_async).with(
              a_hash_including("orphaned_content_ids" => [content_id]),
            )
            put request_path, params: payload.to_json
          end
        end

        context "published edition" do
          let(:edition) { create(:live_edition, document:, base_path:) }

          it "passes the old link to dependency resolution" do
            expect(DownstreamDraftJob).to receive(:perform_async).with(
              a_hash_including("orphaned_content_ids" => [content_id]),
            )
            put request_path, params: payload.to_json
          end
        end
      end
    end

    context "when creating a draft for a previously unpublished edition" do
      before do
        Timecop.freeze(Time.zone.local(2017, 9, 1, 12, 0, 0))
        create(
          :unpublished_edition,
          document: create(:document, content_id:, stale_lock_version: 2),
          user_facing_version: 5,
          base_path:,
        )
      end

      after do
        Timecop.return
      end

      it "creates the draft's lock version using the unpublished lock version as a starting point" do
        put request_path, params: content_item_params.to_json

        edition = Edition.last

        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)
        expect(edition.state).to eq("draft")
        expect(edition.document.stale_lock_version).to eq(3)
      end

      it "creates the draft's user-facing version using the unpublished user-facing version as a starting point" do
        put request_path, params: content_item_params.to_json

        edition = Edition.last

        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)
        expect(edition.state).to eq("draft")
        expect(edition.user_facing_version).to eq(6)
      end
    end

    context "when creating a draft for a previously published edition" do
      before do
        stub_request(:put, %r{.*content-store.*/content/.*})
        Timecop.freeze(Time.zone.local(2017, 9, 1, 12, 0, 0))
      end

      after do
        Timecop.return
      end

      let(:first_published_at) { 1.year.ago }
      let(:major_published_at) { 1.year.ago }

      let(:document) do
        create(
          :document,
          content_id:,
          stale_lock_version: 5,
        )
      end

      let!(:edition) do
        create(
          :live_edition,
          document:,
          user_facing_version: 5,
          first_published_at:,
          base_path:,
          major_published_at:,
        )
      end

      let!(:link) do
        edition.links.create(
          link_type: "test",
          target_content_id: document.content_id,
        )
      end

      it "creates the draft's user-facing version using the live's user-facing version as a starting point" do
        put request_path, params: content_item_params.to_json

        edition = Edition.last

        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)
        expect(edition.state).to eq("draft")
        expect(edition.user_facing_version).to eq(6)
      end

      it "sets first_published_at to the previously published version's value" do
        payload = content_item_params
        payload.delete(:first_published_at)

        put request_path, params: payload.to_json

        edition = Edition.last
        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)

        expect(edition.first_published_at).to eq(first_published_at)
      end

      context "when first_published_at has changed in the payload" do
        it "updates first_published_at" do
          put request_path, params: content_item_params.to_json

          edition = Edition.last
          expect(edition.first_published_at).to eq(content_item_params[:first_published_at])
        end
      end

      context "when update_type is minor" do
        let(:payload) do
          content_item_params.merge!({
            update_type: "minor",
          })
        end

        it "sets major_published_at to previous published edition's value" do
          put request_path, params: payload.to_json

          edition = Edition.last
          expect(edition.major_published_at.iso8601)
            .to eq(major_published_at.iso8601)
        end
      end

      context "when the base path has changed" do
        let(:payload) do
          content_item_params.merge!({
            base_path: "/moved",
            routes: [{ path: "/moved", type: "exact" }],
          })
        end

        it "sets the correct base path on the location" do
          put request_path, params: payload.to_json

          expect(Edition.where(base_path: "/moved", state: "draft")).to exist
        end

        it "creates a redirect" do
          put request_path, params: payload.to_json

          redirect = Edition.find_by(
            base_path:,
            state: "draft",
          )

          expect(redirect).to be_present
          expect(redirect.schema_name).to eq("redirect")
          expect(redirect.publishing_app).to eq("publisher")

          expect(redirect.redirects).to eq([{
            path: base_path,
            type: "exact",
            destination: "/moved",
          }])

          expect(redirect.document.owning_document).to eq(edition.document)
        end

        it "sends a create request to the draft content store for the redirect" do
          expect(DownstreamDraftJob).to receive(:perform_async).twice

          put request_path, params: payload.to_json
        end
      end
    end

    context "when the payload is for an already drafted edition" do
      before do
        stub_request(:put, %r{.*content-store.*/content/.*})
        Timecop.freeze(Time.zone.local(2017, 9, 1, 12, 0, 0))
      end

      after do
        Timecop.return
      end

      let(:document) do
        create(:document, content_id:, stale_lock_version: 1)
      end

      let!(:previously_drafted_item) do
        create(
          :draft_edition,
          document:,
          base_path:,
          title: "Old Title",
          publishing_app: "publisher",
          update_type: "major",
        )
      end

      it "updates the edition" do
        put request_path, params: content_item_params.to_json

        previously_drafted_item.reload

        expect(previously_drafted_item.title).to eq(content_item_params[:title])
      end

      it "keeps the content_store as draft" do
        put request_path, params: content_item_params.to_json

        previously_drafted_item.reload

        expect(previously_drafted_item.content_store).to eq("draft")
      end

      it "sets last_edited_at to current time" do
        put request_path, params: content_item_params.to_json

        previously_drafted_item.reload

        expect(previously_drafted_item.last_edited_at).to eq(Time.zone.now)
      end

      context "when public_updated_at is in the payload" do
        let(:public_updated_at) { Time.zone.now }

        let(:payload) do
          content_item_params.merge!({
            public_updated_at:,
          })
        end

        it "allows the setting of public_updated_at" do
          put request_path, params: payload.to_json

          previously_drafted_item.reload

          expect(previously_drafted_item.public_updated_at)
            .to eq(public_updated_at)
        end
      end

      context "when first_published_at is in the payload" do
        let(:first_published_at) { Time.zone.parse("2016-5-23 1:00").rfc3339 }

        let(:payload) do
          content_item_params.merge!({
            first_published_at:,
          })
        end

        it "allows the setting of first_published_at and publisher_first_published_at" do
          put request_path, params: payload.to_json

          expect(previously_drafted_item.reload.first_published_at)
            .to eq(first_published_at)
        end
      end

      it "does not increment the user-facing version for the edition" do
        put request_path, params: content_item_params.to_json

        previously_drafted_item.reload

        expect(previously_drafted_item.user_facing_version).to eq(1)
      end

      it "increments the lock version for the document" do
        put request_path, params: content_item_params.to_json

        expect(document.reload.stale_lock_version).to eq(2)
      end

      context "when the base path has changed" do
        before do
          previously_drafted_item.update!(
            routes: [{ path: "/old-path", type: "exact" }, { path: "/old-path.atom", type: "exact" }],
            base_path: "/old-path",
          )
        end

        it "updates the location's base path" do
          put request_path, params: content_item_params.to_json
          previously_drafted_item.reload

          expect(previously_drafted_item.base_path).to eq(base_path)
        end

        context "when there is a draft at the new base path" do
          let!(:substitute_item) do
            create(
              :draft_edition,
              base_path:,
              title: "Substitute Content",
              publishing_app: "publisher",
              document_type: "coming_soon",
            )
          end

          it "deletes the substitute item" do
            put request_path, params: content_item_params.to_json
            expect(Edition.exists?(id: substitute_item.id)).to eq(false)
          end

          context "conflicting version" do
            before do
              previously_drafted_item.document.update!(stale_lock_version: 2)
            end

            let(:payload) do
              content_item_params.merge!({
                previous_version: "1",
              })
            end

            it "doesn't delete the substitute item" do
              put request_path, params: payload.to_json

              expect(response.status).to eq(409)
              expect(response.body).to match(/lock-version conflict/)
              expect(Edition.exists?(id: substitute_item.id)).to eq(true)
            end
          end
        end
      end

      context "with a 'previous_version' which does not match the current lock_version of the draft item" do
        before do
          previously_drafted_item.document.update!(stale_lock_version: 2)
        end

        let(:payload) do
          content_item_params.merge!({
            previous_version: "1",
          })
        end

        it "raises an error" do
          put request_path, params: payload.to_json

          expect(response.status).to eq(409)
          expect(response.body).to match(/lock-version conflict/)
        end
      end

      context "when some of the attributes are not provided in the payload" do
        before do
          payload.delete(:redirects)
          payload.delete(:phase)
        end

        let(:payload) do
          content_item_params.merge!({})
        end

        it "resets those attributes to their defaults from the database" do
          put request_path, params: payload.to_json
          edition = Edition.last

          expect(edition.redirects).to eq([])
          expect(edition.phase).to eq("live")
        end
      end

      context "when the auth_bypass_ids has been updated" do
        let(:auth_bypass_ids) { [SecureRandom.uuid] }

        let(:payload) do
          content_item_params.merge!({
            auth_bypass_ids:,
          })
        end

        it "updates the edition with auth_bypass_ids params" do
          put request_path, params: payload.to_json
          expect(Edition.last.auth_bypass_ids).to eq(auth_bypass_ids)
        end
      end

      context "when the change note has been updated" do
        let(:change_note) { "updated note" }

        let(:payload) do
          content_item_params.merge!({
            change_note:,
          })
        end

        it "updates the change note" do
          expect { put request_path, params: payload.to_json }
            .to change { previously_drafted_item.change_note.reload.note }
            .from("note").to(change_note)
        end
      end

      context "when the change note has been removed" do
        let(:payload) do
          content_item_params.merge!({
            update_type: "minor",
          })
        end

        it "removes the change note" do
          expect { put request_path, params: payload.to_json }
            .to change(ChangeNote, :count).by(-1)
        end
      end
    end
  end

  describe "POST /publish" do
    let(:publishing_platform_request_id) { "test" }
    let!(:document) { create(:document, content_id:) }
    let!(:edition) { create(:edition, document:, base_path:) }
    let(:request_path) { "/content/#{content_id}/publish" }

    context "for an existing draft edition" do
      before do
        post request_path, params: {}.to_json, headers: { "HTTP_PUBLISHING_PLATFORM_REQUEST_ID" => publishing_platform_request_id }
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the content_id of the published item" do
        expect(parsed_response.keys).to include("content_id")
        expect(parsed_response["content_id"]).to eq(content_id)
      end

      it "updates the publishing_request_id" do
        edition = Edition.last
        expect(edition.publishing_request_id).to eq(publishing_platform_request_id)
      end
    end

    context "for an edition with dependencies" do
      let(:link_set) do
        create(
          :link_set,
          content_id:,
          document:,
        )
      end

      let(:draft_target_edition) { create(:edition, base_path: "/foo", title: "foo") }

      before do
        create(:link, link_set:, link_type: "parent", target_content_id: draft_target_edition.document.content_id)
      end

      it "doesn't send draft dependencies to the live content store" do
        allow(PublishingApi.service(:live_content_store)).to receive(:put_content_item)
        allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
        expect(PublishingApi.service(:live_content_store)).to_not receive(:put_content_item)
          .with(a_hash_including(base_path: "/foo"))

        post request_path, params: {}.to_json

        expect(response.status).to eq(200)
      end

      # TODO: uncomment when message queue implemented
      # it "doesn't send draft dependencies to the message queue" do
      #   allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
      #   allow(PublishingApi.service(:live_content_store)).to receive(:put_content_item)
      #   expect(PublishingApi.service(:queue_publisher)).to receive(:send_message)
      #     .with(a_hash_including(base_path:), event_type: "major")
      #   expect(PublishingAPI.service(:queue_publisher)).to_not receive(:send_message)
      #     .with(a_hash_including(base_path: "/foo"), event_type: anything)

      #   post request_path, params: {}.to_json

      #   expect(response.status).to eq(200)
      # end
    end

    it "sends to the live content store" do
      allow(PublishingApi.service(:live_content_store)).to receive(:put_content_item).with(anything)
      expect(PublishingApi.service(:live_content_store)).to receive(:put_content_item)
        .with(
          base_path:,
          content_item: a_hash_including(
            content_id:,
            payload_version: anything,
          ),
        )

      post request_path, params: {}.to_json

      expect(response.status).to eq(200)
    end

    context "with a 'previous_version' which matches the current lock version of the draft item" do
      let(:body) { { previous_version: 1 } }

      before do
        post request_path, params: body.to_json
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end
    end

    context "with a 'previous_version' which does not match the current lock version of the draft item" do
      let(:body) { { previous_version: 2 } }

      before do
        post request_path, params: body.to_json
      end

      it "responds with 409" do
        expect(response.status).to eq(409)
        expect(parsed_response["error"]["message"]).to match("A lock-version conflict occurred")
      end
    end

    context "when publishing a draft which has a different content_id to the published edition on the same base_path" do
      let(:live_document) { create(:document, stale_lock_version: 5) }

      before do
        stub_request(:put, %r{.*content-store.*/content/.*})
      end

      context "when both editions are 'regular' editions" do
        before do
          create(
            :live_edition,
            document: live_document,
            base_path:,
          )
        end

        it "raises an error" do
          post request_path, params: {}.to_json

          expect(response.status).to eq(422)
        end
      end
    end

    context "for a non-existent edition" do
      let(:request_path) { "/content/#{SecureRandom.uuid}/publish" }

      before do
        post request_path, params: {}.to_json
      end

      it "responds with 404" do
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /republish" do
    let(:publishing_platform_request_id) { "test" }
    let!(:document) { create(:document, content_id:) }
    let!(:edition) { create(:live_edition, document:) }
    let(:request_path) { "/content/#{content_id}/republish" }

    context "for an existing live edition" do
      before do
        post request_path, params: {}.to_json, headers: { "HTTP_PUBLISHING_PLATFORM_REQUEST_ID" => publishing_platform_request_id }
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the content_id of the published item" do
        expect(parsed_response.keys).to include("content_id")
        expect(parsed_response["content_id"]).to eq(content_id)
      end

      it "updates the publishing_request_id" do
        edition = Edition.last
        expect(edition.publishing_request_id).to eq(publishing_platform_request_id)
      end
    end

    context "with a 'previous_version' which matches the current lock version of the draft item" do
      let(:body) { { previous_version: 1 } }

      before do
        post request_path, params: body.to_json
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end
    end

    context "with a 'previous_version' which does not match the current lock version of the draft item" do
      let(:body) { { previous_version: 2 } }

      before do
        post request_path, params: body.to_json
      end

      it "responds with 409" do
        expect(response.status).to eq(409)
        expect(parsed_response["error"]["message"]).to match("A lock-version conflict occurred")
      end
    end

    context "for a draft edition" do
      let!(:edition) { create(:draft_edition, document:) }

      before do
        post request_path, params: {}.to_json
      end

      it "responds with 404" do
        expect(response.status).to eq(404)
      end
    end

    context "for a non-existent edition" do
      let(:request_path) { "/content/#{SecureRandom.uuid}/republish" }

      before do
        post request_path, params: {}.to_json
      end

      it "responds with 404" do
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /discard-draft" do
    let(:document) { create(:document, content_id:) }
    let(:request_path) { "/content/#{content_id}/discard-draft" }

    context "when a draft edition exists" do
      let!(:draft_edition) do
        create(
          :draft_edition,
          document:,
          title: "draft",
          base_path:,
        )
      end

      it "does not send to the live content store" do
        expect(PublishingApi.service(:live_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /[^-]content-store.*/)

        post request_path, params: {}.to_json

        expect(response.status).to eq(200)
      end

      it "deletes the edition from the draft content store" do
        expect(PublishingApi.service(:draft_content_store)).to receive(:delete_content_item)
          .with(base_path)

        post request_path, params: {}.to_json

        expect(response.status).to eq(200)
      end

      it "deletes the edition from the database" do
        post request_path, params: {}.to_json

        expect(response.status).to eq(200)
        expect(Edition.count).to eq(0)
      end
    end

    context "when a draft edition does not exist" do
      it "responds with 404" do
        post request_path, params: {}.to_json

        expect(response.status).to eq(404)
      end

      it "does not send to either content store" do
        expect(WebMock).not_to have_requested(:any, /.*content-store.*/)
        expect(PublishingApi.service(:draft_content_store)).not_to receive(:put_content_item)
        expect(PublishingApi.service(:live_content_store)).not_to receive(:put_content_item)

        post request_path, params: {}.to_json
      end

      context "and a live edition exists" do
        before do
          create(:live_edition, document:)
        end

        it "returns a 422" do
          post request_path, params: {}.to_json

          expect(response.status).to eq(422)
        end

        it "does not send to either content store" do
          expect(WebMock).not_to have_requested(:any, /.*content-store.*/)
          expect(PublishingApi.service(:draft_content_store)).not_to receive(:put_content_item)
          expect(PublishingApi.service(:live_content_store)).not_to receive(:put_content_item)

          post request_path, params: {}.to_json
        end
      end
    end
  end

  describe "POST /unpublish" do
    let(:request_path) { "/content/#{content_id}/unpublish" }
    let(:document) { create(:document, content_id:) }
    let!(:edition) do
      create(
        :live_edition,
        document:,
        base_path:,
      )
    end

    describe "withdrawing" do
      let(:withdrawal_params) do
        {
          type: "withdrawal",
          explanation: "Test withdrawal",
        }.to_json
      end
      let(:withdrawal_response) do
        {
          base_path:,
          content_item: a_hash_including(
            withdrawn_notice: {
              explanation: "Test withdrawal",
              withdrawn_at: Time.zone.now.iso8601,
            },
          ),
        }
      end

      it "creates an Unpublishing" do
        post request_path, params: withdrawal_params

        expect(response.status).to eq(200)

        unpublishing = Unpublishing.find_by(edition:)
        expect(unpublishing.type).to eq("withdrawal")
        expect(unpublishing.explanation).to eq("Test withdrawal")
      end

      it "sends the withdrawal information to the live content store" do
        Timecop.freeze do
          expect(PublishingApi.service(:live_content_store)).to receive(:put_content_item)
            .with(withdrawal_response)

          post request_path, params: withdrawal_params

          expect(response.status).to eq(200)
        end
      end

      it "sends the withdrawal information to the draft content store" do
        Timecop.freeze do
          expect(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
            .with(withdrawal_response)

          post request_path, params: withdrawal_params

          expect(response.status).to eq(200)
        end
      end

      # TODO: uncomment when message queue implemented
      # it "sends to the message queue" do
      #   allow(PublishingApi.service(:live_content_store)).to receive(:put_content_item)
      #   allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
      #   expect(PublishingApi.service(:queue_publisher)).to receive(:send_message)
      #     .with(a_hash_including(document_type: "answer"), event_type: "unpublish")

      #   post request_path, params: withdrawal_params

      #   expect(response.status).to eq(200)
      # end
    end

    describe "redirecting" do
      let(:redirect_params_with_alternative_path) do
        {
          type: "redirect",
          alternative_path: "/new-path",
        }.to_json
      end
      let(:redirect_params_with_redirects_hash) do
        {
          type: "redirect",
          redirects: [
            {
              path: base_path,
              type: :exact,
              destination: "/new-path",
            },
          ],
        }.to_json
      end
      let(:redirect_response) do
        {
          base_path:,
          content_item: {
            document_type: "redirect",
            schema_name: "redirect",
            base_path:,
            publishing_app: edition.publishing_app,
            public_updated_at: Time.zone.now.iso8601,
            first_published_at: edition.first_published_at.iso8601,
            redirects: [
              {
                path: base_path,
                type: "exact",
                destination: "/new-path",
              },
            ],
            payload_version: anything,
          },
        }
      end

      shared_examples "unpublishing with redirects" do
        it "creates an Unpublishing" do
          post request_path, params: redirect_params

          expect(response.status).to eq(200)

          unpublishing = Unpublishing.find_by(edition:)
          expect(unpublishing.type).to eq("redirect")
          expect(unpublishing.redirects).to match_array([
            a_hash_including(destination: "/new-path"),
          ])
        end

        it "sends a redirect to the live content store" do
          Timecop.freeze do
            expect(PublishingApi.service(:live_content_store)).to receive(:put_content_item)
              .with(redirect_response)

            post request_path, params: redirect_params

            expect(response.status).to eq(200)
          end
        end

        it "sends a redirect to the draft content store" do
          Timecop.freeze do
            expect(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
              .with(redirect_response)

            post request_path, params: redirect_params

            expect(response.status).to eq(200)
          end
        end

        # TODO: uncomment when message queue implemented
        # it "sends to the message queue" do
        #   allow(PublishingApi.service(:live_content_store)).to receive(:put_content_item)
        #   allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
        #   expect(PublishingApi.service(:queue_publisher)).to receive(:send_message)
        #     .with(
        #       a_hash_including(
        #         document_type: "redirect",
        #         redirects: [a_hash_including(destination: "/new-path")],
        #       ),
        #       event_type: "unpublish",
        #     )

        #   post request_path, params: redirect_params

        #   expect(response.status).to eq(200)
        # end
      end

      context "with a redirects hash payload" do
        let(:redirect_params) { redirect_params_with_redirects_hash }
        it_behaves_like "unpublishing with redirects"
      end

      context "with an alternative_path payload" do
        let(:redirect_params) { redirect_params_with_alternative_path }
        it_behaves_like "unpublishing with redirects"
      end
    end

    describe "gone (remove the content)" do
      let(:gone_params) do
        {
          type: "gone",
          explanation: "Test gone",
          alternative_path: "/new-path",
        }.to_json
      end
      let(:gone_response) do
        {
          base_path:,
          content_item: {
            base_path:,
            document_type: "gone",
            schema_name: "gone",
            publishing_app: edition.publishing_app,
            details: {
              explanation: "Test gone",
              alternative_path: "/new-path",
            },
            routes: [
              {
                path: base_path,
                type: "exact",
              },
            ],
            payload_version: anything,
            public_updated_at: anything,
          },
        }
      end

      it "creates an Unpublishing" do
        post request_path, params: gone_params

        expect(response.status).to eq(200)

        unpublishing = Unpublishing.find_by(edition:)
        expect(unpublishing.type).to eq("gone")
        expect(unpublishing.explanation).to eq("Test gone")
        expect(unpublishing.alternative_path).to eq("/new-path")
      end

      it "sends an unpublishing to the live content store" do
        Timecop.freeze do
          expect(PublishingApi.service(:live_content_store)).to receive(:put_content_item)
            .with(gone_response)

          post request_path, params: gone_params

          expect(response.status).to eq(200)
        end
      end

      it "sends an unpublishing to the draft content store" do
        Timecop.freeze do
          expect(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
            .with(gone_response)

          post request_path, params: gone_params

          expect(response.status).to eq(200)
        end
      end

      # TODO: uncomment when message queue implemented
      # it "sends to the message queue" do
      #   allow(PublishingApi.service(:live_content_store)).to receive(:put_content_item)
      #   allow(PublishingApi.service(:draft_content_store)).to receive(:put_content_item)
      #   expect(PublishingApi.service(:queue_publisher)).to receive(:send_message)
      #     .with(
      #       a_hash_including(
      #         document_type: "gone",
      #         content_id:,
      #         details: a_hash_including(alternative_path: "/new-path"),
      #       ),
      #       event_type: "unpublish",
      #     )

      #   post request_path, params: gone_params

      #   expect(response.status).to eq(200)
      # end
    end

    describe "vanish (gone like it never existed)" do
      let(:vanish_params) do
        {
          type: "vanish",
        }.to_json
      end

      it "creates an Unpublishing" do
        post request_path, params: vanish_params

        expect(response.status).to eq(200)

        unpublishing = Unpublishing.find_by(edition:)
        expect(unpublishing.type).to eq("vanish")
      end

      it "deletes the content from the live content store" do
        Timecop.freeze do
          expect(PublishingApi.service(:live_content_store)).to receive(:delete_content_item)
            .with(base_path)

          post request_path, params: vanish_params

          expect(response.status).to eq(200)
        end
      end

      it "deletes the content from the draft content store" do
        Timecop.freeze do
          expect(PublishingApi.service(:draft_content_store)).to receive(:delete_content_item)
            .with(base_path)

          post request_path, params: vanish_params

          expect(response.status).to eq(200)
        end
      end

      # TODO: uncomment when message queue implemented
      # it "sends to the message queue" do
      #   allow(PublishingApi.service(:live_content_store)).to receive(:delete_content_item)
      #   allow(PublishingApi.service(:draft_content_store)).to receive(:delete_content_item)
      #   expect(PublishingApi.service(:queue_publisher)).to receive(:send_message)
      #     .with(
      #       a_hash_including(document_type: "vanish"),
      #       event_type: "unpublish",
      #     )

      #   post request_path, params: vanish_params

      #   expect(response.status).to eq(200)
      # end
    end

    describe "a bad unpublishing type" do
      it "422s" do
        post request_path,
             params: {
               type: "not-correct",
             }.to_json

        expect(response.status).to eq(422)
      end
    end

    context "document is already unpublished" do
      let!(:edition) do
        create(
          :unpublished_edition,
          document:,
          base_path: "/vat-rates",
          explanation: "This explnatin has a typo",
          alternative_path: "/new-path",
        )
      end

      let(:payload) do
        {
          content_id:,
          type: "gone",
          explanation: "This explanation is correct",
        }
      end

      it "maintains the state of unpublished" do
        post request_path, params: payload.to_json
        expect(edition.reload.state).to eq("unpublished")
      end

      it "updates the Unpublishing" do
        unpublishing = Unpublishing.find_by(edition:)
        expect(unpublishing.explanation).to eq("This explnatin has a typo")

        post request_path, params: payload.to_json

        unpublishing.reload

        expect(unpublishing.explanation).to eq("This explanation is correct")
        expect(unpublishing.alternative_path).to be_nil
      end

      it "sends an unpublishing to the draft content store" do
        expect(DownstreamDraftJob).to receive(:perform_async)
          .with(
            a_hash_including("content_id" => content_id),
          )

        post request_path, params: payload.to_json
      end

      it "sends an unpublishing to the live content store" do
        expect(DownstreamLiveJob).to receive(:perform_async)
          .with(
            a_hash_including("content_id" => content_id),
          )

        post request_path, params: payload.to_json
      end

      context "when the unpublishing type is substitute" do
        let!(:edition) do
          create(
            :substitute_unpublished_edition,
            document:,
          )
        end

        it "rejects the request with a 404" do
          post request_path, params: payload.to_json
          expect(response.status).to eq(404)
          expect(response.body).to match(/Could not find an edition to unpublish/)
        end
      end
    end
  end
end
