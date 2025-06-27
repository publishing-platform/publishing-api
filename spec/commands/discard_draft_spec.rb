require "rails_helper"

RSpec.describe Commands::DiscardDraft do
  describe "call" do
    before do
      stub_request(:delete, %r{.*content-store.*/content/.*})
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:expected_content_store_payload) { { base_path: "/vat-rates" } }
    let(:document) do
      create(
        :document,
        stale_lock_version:,
      )
    end
    let(:stale_lock_version) { 1 }
    let(:base_path) { "/vat-rates" }
    let(:payload) { { content_id: document.content_id } }

    before do
      allow_any_instance_of(Presenters::EditionPresenter)
        .to receive(:for_content_store)
        .and_return(expected_content_store_payload)
    end

    context "when a draft edition exists for the given content_id" do
      let(:user_facing_version) { 2 }
      let!(:existing_draft_item) do
        create(
          :edition,
          document:,
          base_path:,
          user_facing_version:,
        )
      end
      let!(:change_note) { ChangeNote.create(edition: existing_draft_item) }
      let(:publishing_app) { existing_draft_item.publishing_app }

      it "deletes the draft item" do
        expect {
          described_class.call(payload)
        }.to change(Edition, :count).by(-1)

        expect(Edition.exists?(id: existing_draft_item.id)).to eq(false)
      end

      context "creates an action" do
        let(:content_id) { document.content_id }
        let(:action_payload) { payload }
        let(:action) { "DiscardDraft" }
        include_examples "creates an action"
      end

      it "deletes the supporting objects for the draft item" do
        described_class.call(payload)

        change_notes = ChangeNote.where(edition: existing_draft_item)

        expect(change_notes).to be_empty
      end

      it "deletes the draft item from the draft content store" do
        expect(DownstreamDiscardDraftJob).to receive(:perform_async)
          .with(
            a_hash_including(
              "base_path" => base_path,
              "content_id" => document.content_id,
              "source_command" => "discard_draft",
              "source_document_type" => "answer",
            ),
          )

        described_class.call(payload)
      end

      it "deletes any path reservations for the base_path and publishing app" do
        create(:path_reservation, base_path:, publishing_app:)

        expect { described_class.call(payload) }
          .to change { PathReservation.where(base_path:).count }
          .by(-1)
      end

      it "doesn't delete a path reservation reserved by a different application" do
        create(:path_reservation, base_path:, publishing_app: "different")

        expect { described_class.call(payload) }
          .not_to(change { PathReservation.where(base_path:).count })
      end

      it "doesn't delete a previous path reservation if it's used by a live "\
        "edition published by the same app" do
        create(:live_edition, base_path:, publishing_app:)
        create(:path_reservation, base_path:, publishing_app:)

        expect { described_class.call(payload) }
          .not_to(change { PathReservation.where(base_path:).count })
      end

      it "deletes a previous path reservation if it's used by a live "\
        "edition published by a different app" do
        create(:live_edition, base_path:, publishing_app: "different-app")
        create(:path_reservation, base_path:, publishing_app:)

        expect { described_class.call(payload) }
          .to change { PathReservation.where(base_path:).count }
          .by(-1)
      end

      it "does not send any request to the live content store" do
        expect(DownstreamLiveJob).not_to receive(:perform_async)
        described_class.call(payload)
      end

      it "does not send any messages on the message queue" do
        expect(PublishingApi.service(:queue_publisher)).not_to receive(:send_message)
        described_class.call(payload)
      end

      context "when the draft's lock version differs from the given lock version" do
        before do
          payload[:previous_version] = document.stale_lock_version - 1
        end

        it "raises an error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, /Conflict/)
        end
      end

      context "when a published edition exists with the same base_path" do
        let(:stale_lock_version) { 3 }
        let!(:published_item) do
          create(
            :live_edition,
            document:,
            base_path:,
            user_facing_version: user_facing_version - 1,
          )
        end

        it "increments the lock version of the published item" do
          expect {
            described_class.call(payload)
          }.to change { document.reload.stale_lock_version }.to(4)
        end

        it "it uses the downstream discard draft worker" do
          expect(DownstreamDiscardDraftJob).to receive(:perform_async)
            .with(
              a_hash_including(
                "base_path" => base_path,
                "content_id" => document.content_id,
                "source_command" => "discard_draft",
                "source_document_type" => "answer",
              ),
            )
          described_class.call(payload)
        end

        it "deletes the supporting objects for the draft item" do
          described_class.call(payload)

          change_notes = ChangeNote.where(edition: existing_draft_item)

          expect(change_notes).to be_empty
        end

        it "deletes the draft" do
          expect {
            described_class.call(payload)
          }.to change(Edition, :count).by(-1)
        end
      end

      context "a published edition exists with a different base_path" do
        let!(:published_item) do
          create(
            :live_edition,
            document:,
            base_path: "/hat-rates",
            user_facing_version: user_facing_version - 1,
          )
        end

        it "it uses downstream discard draft worker" do
          expect(DownstreamDiscardDraftJob).to receive(:perform_async)
            .with(
              a_hash_including(
                "base_path" => base_path,
                "content_id" => document.content_id,
                "source_command" => "discard_draft",
                "source_document_type" => "answer",
              ),
            )
          described_class.call(payload)
        end
      end

      context "an unpublished edition exits" do
        let(:unpublished_item) do
          create(
            :unpublished_edition,
            document:,
            base_path:,
            user_facing_version: user_facing_version - 1,
          )
        end

        it "it uses downstream discard draft worker" do
          expect(DownstreamDiscardDraftJob).to receive(:perform_async)
            .with(
              a_hash_including(
                "base_path" => base_path,
                "content_id" => document.content_id,
                "source_command" => "discard_draft",
                "source_document_type" => "answer",
              ),
            )
          described_class.call(payload)
        end
      end

      it_behaves_like TransactionalCommand
    end

    context "when no draft edition exists for the given content_id" do
      it "raises a command error with code 404" do
        expect { described_class.call(payload) }.to raise_error(CommandError) do |error|
          expect(error.code).to eq(404)
        end
      end

      context "and a published edition exists" do
        before do
          create(:live_edition, document:)
        end

        it "raises a command error with code 422" do
          expect { described_class.call(payload) }.to raise_error(CommandError) do |error|
            expect(error.code).to eq(422)
          end
        end
      end
    end
  end
end
