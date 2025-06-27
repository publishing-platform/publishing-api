require "rails_helper"

RSpec.describe Commands::Publish do
  describe "call" do
    before do
      Timecop.freeze(Time.zone.local(2017, 9, 1, 12, 0, 0))
    end

    after do
      Timecop.return
    end

    let(:base_path) { "/vat-rates" }
    let(:user_facing_version) { 5 }
    let(:major_published_at) { 1.year.ago }
    let(:public_updated_at) { 1.year.ago }

    let!(:document) do
      create(
        :document,
        stale_lock_version: 2,
      )
    end

    let!(:draft_item) do
      create(
        :draft_edition,
        document:,
        base_path:,
        user_facing_version:,
      )
    end

    let(:expected_content_store_payload) { { base_path: } }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})

      allow(DependencyResolutionJob).to receive(:perform_async)
    end

    around do |example|
      Timecop.freeze { example.run }
    end

    let(:payload) do
      {
        content_id: document.content_id,
        previous_version: 2,
      }
    end

    it "sets the source_command to publish" do
      expect(DownstreamLiveJob).to receive(:perform_async)
        .with(hash_including("source_command" => "publish"))

      described_class.call(payload)
    end

    it "sets the source_fields to the correct value" do
      expect(DownstreamLiveJob)
        .to receive(:perform_async)
        .with(
          hash_including(
            "source_fields" => [],
          ),
        )

      described_class.call(payload)
    end

    context "publishing draft edition" do
      let(:existing_base_path) { base_path }

      let!(:draft_item) do
        create(
          :draft_edition,
          document:,
          base_path: existing_base_path,
          title: "foo",
          user_facing_version:,
        )
      end

      it "updates the dependencies" do
        expect(DownstreamDraftJob)
          .to receive(:perform_async)
          .with(a_hash_including("update_dependencies" => true))
        expect(DownstreamLiveJob)
          .to receive(:perform_async)
          .with(a_hash_including("update_dependencies" => true))

        described_class.call(payload)
      end

      it "updates the published_at time to current time" do
        described_class.call(payload)

        expect(draft_item.reload.published_at).to eq(Time.zone.now)
      end

      context "and update_type is major" do
        before do
          draft_item.update!(update_type: "major")
        end

        it "sets major_published_at to current time" do
          described_class.call(payload)

          edition = Edition.last
          expect(edition.major_published_at).to eq(Time.zone.now)
        end
      end

      context "and update_type is minor" do
        it "sets major_published_at to previous live version's value" do
          create(
            :live_edition,
            document:,
            base_path: existing_base_path,
            user_facing_version: user_facing_version - 1,
            major_published_at:,
          )

          described_class.call(payload)

          edition = Edition.last
          expect(edition.major_published_at).to eq(major_published_at)
        end

        it "does not set major_published_at if edition does not have a major version" do
          described_class.call(payload)

          edition = Edition.last
          expect(edition.major_published_at).to be_nil
        end
      end
    end

    context "dependency fields change on new publication" do
      let(:existing_base_path) { base_path }

      let!(:live_item) do
        create(
          :live_edition,
          document:,
          base_path: existing_base_path,
          title: "foo",
          user_facing_version: user_facing_version - 1,
        )
      end

      it "updates the dependencies" do
        expect(DownstreamDraftJob)
          .to receive(:perform_async)
          .with(a_hash_including("update_dependencies" => true))

        expect(DownstreamLiveJob)
          .to receive(:perform_async)
          .with(a_hash_including("update_dependencies" => true))

        described_class.call(payload)
      end

      it "sets the source_fields to the correct value" do
        expect(DownstreamLiveJob).to(
          receive(:perform_async)
            .with(
              hash_including(
                "source_fields" => contain_exactly("title"),
              ),
            ),
        )

        described_class.call(payload)
      end
    end

    context "dependency fields don't change between publications" do
      let(:existing_base_path) { base_path }

      let!(:live_item) do
        create(
          :live_edition,
          document:,
          base_path: existing_base_path,
          user_facing_version: user_facing_version - 1,
        )
      end

      it "doesn't updates the dependencies" do
        expect(DownstreamDraftJob)
          .to receive(:perform_async)
          .with(a_hash_including("update_dependencies" => false))

        expect(DownstreamLiveJob)
          .to receive(:perform_async)
          .with(a_hash_including("update_dependencies" => false))

        described_class.call(payload)
      end
    end

    context "when the edition was previously published" do
      let(:existing_base_path) { base_path }
      let(:first_published_at) { 1.year.ago }
      let!(:live_item) do
        create(
          :live_edition,
          document:,
          base_path: existing_base_path,
          user_facing_version: user_facing_version - 1,
          first_published_at:,
        )
      end

      it "marks the previously published item as 'superseded'" do
        described_class.call(payload)

        superseded = Edition.find(live_item.id)
        expect(superseded.state).to eq("superseded")
      end
    end

    context "when the edition was previously unpublished" do
      let!(:live_item) do
        create(
          :unpublished_edition,
          document: draft_item.document,
          base_path:,
          user_facing_version: user_facing_version - 1,
        )
      end

      it "marks the previously unpublished item as 'superseded'" do
        described_class.call(payload)

        unpublished = Edition.find(live_item.id)
        expect(unpublished.state).to eq("superseded")
      end
    end

    context "when another edition is blocking the publish action" do
      let!(:other_edition) do
        create(
          :redirect_live_edition,
          document: create(:document),
          base_path:,
        )
      end

      it "unpublishes the edition which is in the way" do
        expect(PublishingApi.service(:queue_publisher)).to receive(:send_message).with(
          hash_including(content_id: other_edition.content_id, document_type: "substitute"),
          hash_including(event_type: "unpublish"),
        )
        expect(PublishingApi.service(:queue_publisher)).to receive(:send_message).with(
          hash_including(content_id: draft_item.content_id),
          hash_including(event_type: "minor"),
        )

        described_class.call(payload)

        updated_other_edition = Edition.find(other_edition.id)

        expect(updated_other_edition.state).to eq("unpublished")
        expect(updated_other_edition.base_path).to eq(base_path)
      end
    end

    context "with a 'previous_version' which does not match the current lock version of the draft item" do
      before do
        payload.merge!(previous_version: 1)
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /Conflict/)
      end
    end

    context "with a valid payload" do
      it "changes the state of the draft item to 'published'" do
        described_class.call(payload)

        updated_draft_item = Edition.find(draft_item.id)
        expect(updated_draft_item.state).to eq("published")
      end

      it "sends downstream asynchronously" do
        expect(DownstreamLiveJob)
          .to receive(:perform_async)
          .with(
            a_hash_including("content_id"),
          )

        described_class.call(payload)
      end

      context "creates an action" do
        let(:content_id) { document.content_id }
        let(:action_payload) { payload }
        let(:action) { "Publish" }
        include_examples "creates an action"
      end

      context "when the 'downstream' parameter is false" do
        it "does not send downstream" do
          expect(DownstreamLiveJob).not_to receive(:perform_async)
          described_class.call(payload, downstream: false)
        end
      end

      context "with a public_updated_at set on the draft edition" do
        before do
          draft_item.update!(public_updated_at:)
        end

        context "and the update_type is minor" do
          it "public_updated_at does not change" do
            described_class.call(payload)

            expect(draft_item.reload.public_updated_at).to eq(public_updated_at)
          end
        end

        context "and the update_type is major" do
          before do
            draft_item.update!(update_type: "major")
          end

          it "public_updated_at does not change" do
            described_class.call(payload)

            expect(draft_item.reload.public_updated_at).to eq(public_updated_at)
          end
        end
      end

      context "with no public_updated_at set on the draft edition" do
        before do
          draft_item.update!(public_updated_at: nil)
        end

        context "and the update_type is minor" do
          let!(:live_item) do
            create(
              :live_edition,
              document:,
              base_path:,
              user_facing_version: user_facing_version - 1,
            )
          end

          context "and the previous live version has public_updated_at" do
            it "updates public_updated_at to previous item's value" do
              described_class.call(payload)

              expect(draft_item.reload.public_updated_at)
                .to eq(live_item.public_updated_at)
            end
          end

          context "and the previous live version does not have public_updated_at" do
            before do
              live_item.update(public_updated_at: nil)
            end

            it "updates public_updated_at to current time" do
              described_class.call(payload)

              expect(draft_item.reload.public_updated_at).to eq(Time.zone.now)
            end
          end
        end

        context "and the update_type is major" do
          before do
            draft_item.update!(update_type: "major")
          end

          it "updates public_updated_at to current time" do
            described_class.call(payload)

            expect(draft_item.reload.public_updated_at).to eq(Time.zone.now)
          end
        end
      end

      context "when update_type is minor" do
        before do
          ChangeNote.create!(edition: draft_item)
        end

        it "deletes associated ChangeNote records" do
          expect { described_class.call(payload) }
            .to change { ChangeNote.count }.by(-1)
        end
      end

      context "when update_type is major" do
        before do
          draft_item.update!(update_type: "major")
          ChangeNote.create!(edition: draft_item)
        end

        it "does not delete associated ChangeNote records" do
          expect { described_class.call(payload) }
            .not_to(change { ChangeNote.count })
        end
      end
    end

    context "with no first_published_at set on the edition" do
      before do
        draft_item.update!(first_published_at: nil)
      end

      it "sets first_published_at to the current time" do
        described_class.call(payload)

        expect(draft_item.reload.first_published_at).to eq(Time.zone.now)
      end
    end

    context "with first_published_at set on the edition" do
      before do
        draft_item.update!(first_published_at: "2014-05-14T13:00:06Z")
      end

      it "does not update first_published_at" do
        described_class.call(payload)

        expect(draft_item.reload.first_published_at).to eq("2014-05-14T13:00:06Z")
      end
    end

    context "when the base_path differs from the previously published item" do
      let!(:live_item) do
        create(
          :live_edition,
          document: draft_item.document,
          base_path: "/hat-rates",
        )
      end

      before do
        create(
          :redirect_draft_edition,
          base_path: "/hat-rates",
        )
      end

      it "publishes the redirect already created, from the old location to the new location" do
        described_class.call(payload)

        redirect = Edition.with_document.find_by(
          base_path: "/hat-rates",
          state: "published",
        )

        expect(redirect).to be_present
        expect(redirect.schema_name).to eq("redirect")
      end

      it "supersedes the previously published item" do
        described_class.call(payload)

        updated_item = Edition.find(live_item.id)
        expect(updated_item.state).to eq("superseded")
      end
    end

    context "when links differ from the previously published edition" do
      let(:link_a) { SecureRandom.uuid }
      let(:link_b) { SecureRandom.uuid }

      let!(:live_item) do
        create(
          :live_edition,
          document:,
          links_hash: { taxons: [link_a] },
        )
      end

      let!(:draft_item) do
        create(
          :draft_edition,
          document:,
          links_hash: { taxons: [link_b] },
          user_facing_version: 2,
        )
      end

      it "sends link_a downstream as an orphaned content_id when draft item is published" do
        expect(DownstreamLiveJob).to receive(:perform_async)
          .with(a_hash_including("orphaned_content_ids" => [link_a]))

        described_class.call(payload)
      end
    end

    context "when the draft edition has auth_bypass_ids" do
      before do
        draft_item.update!(auth_bypass_ids: [SecureRandom.uuid])
      end

      it "resets the auth_bypass_ids" do
        expect { described_class.call(payload) }
          .to change { draft_item.reload.auth_bypass_ids }
          .to([])
      end
    end

    context "when no draft exists to publish" do
      before do
        draft_item.destroy
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /does not exist/)
      end

      context "but a published item does exist" do
        before do
          create(
            :live_edition,
            document:,
            base_path:,
          )
        end

        it "raises an error to indicate it has already been published" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, /already published edition/)
        end
      end
    end

    it_behaves_like TransactionalCommand
  end
end
