require "rails_helper"

RSpec.describe Commands::PutContent do
  describe "call" do
    before do
      stub_request(:delete, %r{.*content-store.*/content/.*})
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:content_id) { SecureRandom.uuid }
    let(:new_content_id) { SecureRandom.uuid }
    let(:base_path) { "/vat-rates" }
    let(:publishing_app) { "publisher" }

    let(:change_note) { "Info" }
    let(:new_change_note) { "Changed Info" }
    let(:payload) do
      {
        content_id:,
        base_path:,
        update_type: "major",
        title: "Some Title",
        publishing_app:,
        rendering_app: "frontend",
        document_type: "answer",
        schema_name: "answer",
        routes: [{ path: base_path, type: "exact" }],
        redirects: [],
        phase: "beta",
        change_note:,
        details: {},
      }
    end

    let(:updated_payload) do
      {
        content_id:,
        base_path:,
        update_type: "major",
        title: "New Title",
        publishing_app:,
        rendering_app: "frontend",
        document_type: "answer",
        schema_name: "answer",
        routes: [{ path: base_path, type: "exact" }],
        redirects: [],
        phase: "beta",
        change_note: new_change_note,
        details: {},
      }
    end

    it "validates the payload" do
      validator = double(:validator)
      expect(Commands::PutContentValidator).to receive(:new)
        .with(payload, instance_of(described_class))
        .and_return(validator)
      expect(validator).to receive(:validate)
      expect(PathReservation).to receive(:reserve_base_path!)
      expect { described_class.call(payload) }.not_to raise_error
    end

    it "sends to the downstream draft worker" do
      expect(DownstreamDraftJob).to receive(:perform_async)
        .with(
          a_hash_including(
            "content_id" => content_id,
            "update_dependencies" => true,
            "source_command" => "put_content",
            "source_fields" => [],
          ),
        )

      described_class.call(payload)
    end

    it "sends to the downstream draft worker only the fields which have changed" do
      described_class.call(payload)

      expect(DownstreamDraftJob)
        .to receive(:perform_async)
        .with(a_hash_including("source_fields" => %w[title]))

      described_class.call(updated_payload)
    end

    it "does not send to the downstream live worker" do
      expect(DownstreamLiveJob).not_to receive(:perform_async)
      described_class.call(payload)
    end

    it "creates an action" do
      expect(Action.count).to be 0
      described_class.call(payload)
      expect(Action.count).to be 1
      described_class.call(updated_payload)
      expect(Action.last.attributes).to match a_hash_including(
        "content_id" => content_id,
        "action" => "PutContent",
      )
    end

    context "when the 'downstream' parameter is false" do
      it "does not send to the downstream draft worker" do
        expect(DownstreamDraftJob).not_to receive(:perform_async)

        described_class.call(payload, downstream: false)
      end
    end

    context "when the payload includes auth_bypass_ids" do
      it "updates edition with root auth_bypass_ids" do
        payload.merge!(auth_bypass_ids: [SecureRandom.uuid])

        described_class.call(payload)
        expect(Edition.last.auth_bypass_ids).to eq(payload[:auth_bypass_ids])
      end
    end

    it_behaves_like TransactionalCommand

    context "when the draft does not exist" do
      context "with a provided last_edited_at" do
        it "stores the provided timestamp" do
          last_edited_at = 1.year.ago

          described_class.call(payload.merge(last_edited_at: last_edited_at.iso8601))

          edition = Edition.last

          expect(edition.last_edited_at.iso8601).to eq(last_edited_at.iso8601)
        end
      end

      it "stores last_edited_at as the current time" do
        Timecop.freeze do
          described_class.call(payload)

          edition = Edition.last

          expect(edition.last_edited_at.iso8601).to eq(Time.zone.now.iso8601)
        end
      end
    end

    context "when the draft does exist" do
      let(:document) { create(:document, content_id:) }
      let!(:edition) { create(:draft_edition, document:) }

      context "with a provided last_edited_at" do
        %w[minor major republish].each do |update_type|
          context "with update_type of #{update_type}" do
            it "stores the provided timestamp" do
              last_edited_at = 1.year.ago

              described_class.call(
                payload.merge(
                  update_type:,
                  last_edited_at: last_edited_at.iso8601,
                ),
              )

              expect(edition.reload.last_edited_at.iso8601).to eq(last_edited_at.iso8601)
            end
          end
        end
      end

      it "stores last_edited_at as the current time" do
        Timecop.freeze do
          described_class.call(payload)

          expect(edition.reload.last_edited_at.iso8601).to eq(Time.zone.now.iso8601)
        end
      end

      it "deletes a previous path reservation if the paths differ" do
        edition.update!(base_path: "/different", routes: [{ path: "/different", type: "exact" }])
        create(:path_reservation, base_path: "/different", publishing_app:)
        expect { described_class.call(payload) }
          .to change { PathReservation.where(base_path: "/different").count }
          .by(-1)
      end

      it "doesn't delete a previous path reservation if the paths are the same" do
        edition.update!(base_path:, routes: [{ path: base_path, type: "exact" }])
        create(:path_reservation, base_path:, publishing_app:)
        expect { described_class.call(payload) }
          .not_to(change { PathReservation.where(base_path:).count })
      end

      it "doesn't delete a previous path reservation if it is registered to a different publishing application" do
        edition.update!(base_path: "/different", routes: [{ path: "/different", type: "exact" }])
        create(:path_reservation, base_path: "/different", publishing_app: "different")
        expect { described_class.call(payload) }
          .not_to(change { PathReservation.where(base_path: "/different").count })
      end

      it "doesn't delete a previous path reservation if it's used by a live "\
        "edition published by the same app" do
        edition.update!(base_path: "/different",
                        routes: [{ path: "/different", type: "exact" }])
        create(:live_edition, base_path: "/different", publishing_app:)
        create(:path_reservation, base_path: "/different", publishing_app:)
        expect { described_class.call(payload) }
          .not_to(change { PathReservation.where(base_path: "/different").count })
      end

      it "deletes a previous path reservation if it's used by a live "\
        "edition published by a different app" do
        edition.update!(base_path: "/different",
                        routes: [{ path: "/different", type: "exact" }])
        create(:live_edition, base_path: "/different", publishing_app: "different-app")
        create(:path_reservation, base_path: "/different", publishing_app:)
        expect { described_class.call(payload) }
          .to change { PathReservation.where(base_path: "/different").count }
          .by(-1)
      end
    end

    context "field doesn't change between drafts" do
      it "doesn't update the dependencies" do
        expect(DownstreamDraftJob).to receive(:perform_async)
          .with(a_hash_including("update_dependencies" => true))
        expect(DownstreamDraftJob).to receive(:perform_async)
          .with(a_hash_including("update_dependencies" => false))
        described_class.call(payload)
        described_class.call(payload)
      end
    end

    context "when content is pathless" do
      context "and schema requires a base_path" do
        before do
          payload.delete(:base_path)
        end
        it "raises an error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, /The payload did not conform to the schema/)
        end
      end
    end

    describe "race conditions" do
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
          first_published_at: 1.year.ago,
          base_path:,
        )
      end

      it "copes with race conditions" do
        described_class.call(payload)
        Commands::Publish.call({ content_id: })

        thread1 = Thread.new { described_class.call(payload) }
        thread2 = Thread.new { described_class.call(payload) }
        thread1.join
        thread2.join

        expect(Edition.all.pluck(:state)).to match_array(%w[superseded published draft])
      end
    end
  end
end
