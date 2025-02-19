require "rails_helper"

RSpec.describe DependencyResolutionJob, :perform do
  let(:content_id) { SecureRandom.uuid }
  let(:document) { create(:document, content_id:) }
  let(:live_edition) { create(:live_edition, document:) }
  let(:content_store) { "Adapters::ContentStore" }
  let(:orphaned_link_content_ids) { [] }

  subject(:worker_perform) do
    described_class.new.perform(
      "content_id" => content_id,
      "content_store" => content_store,
      "orphaned_content_ids" => orphaned_link_content_ids,
    )
  end

  let(:edition_dependee) { double(:edition_dependent, call: []) }
  let(:dependencies) do
    [
      [content_id],
    ]
  end

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
    allow_any_instance_of(Queries::ContentDependencies).to receive(:call).and_return(dependencies)
  end

  it "finds the edition dependees" do
    expect(Queries::ContentDependencies).to receive(:new).with(
      content_id:,
      content_stores: %w[live],
    ).and_return(edition_dependee)
    worker_perform
  end

  it "the dependees get queued in the content store worker" do
    expect(DownstreamLiveJob).to receive(:perform_async).with(
      a_hash_including(
        "content_id",
        # "message_queue_event_type" => "links", # TODO: uncomment when message queue implemented
        "update_dependencies" => false,
      ),
    )
    worker_perform
  end

  context "when orphaned content ids are present" do
    let(:orphaned_link_content_ids) { [create(:edition).content_id] }
    let(:content_store) { "Adapters::DraftContentStore" }

    after do
      worker_perform
    end

    it "sends content ids downstream" do
      expect(DownstreamDraftJob).to receive(:perform_async).with(
        a_hash_including("content_id"),
      )
      expect(DownstreamDraftJob).to receive(:perform_async).with(
        a_hash_including("content_id" => orphaned_link_content_ids.first),
      )
    end

    context "and the orphaned links belong to different content stores" do
      let(:content_store) { "Adapters::ContentStore" }

      it "doesn't send content ids downstream" do
        expect(DownstreamDraftJob).to_not receive(:perform_async).with(
          a_hash_including("content_id" => orphaned_link_content_ids.first),
        )
      end
    end

    context "and the orphaned links are missing an edition" do
      let(:orphaned_link_content_ids) { [create(:document).content_id] }

      it "doesn't send content ids downstream" do
        expect(DownstreamDraftJob).to_not receive(:perform_async).with(
          a_hash_including("content_id" => orphaned_link_content_ids.first),
        )
      end
    end
  end

  context "with a draft version available" do
    let!(:draft_edition) do
      create(
        :draft_edition,
        document:,
        user_facing_version: 2,
      )
    end

    it "doesn't send draft content to the live content store" do
      expect(DownstreamLiveJob).to receive(:perform_async).with(
        a_hash_including(
          "content_id",
        ),
      )

      described_class.new.perform(
        "content_id" => draft_edition.content_id,
        "content_store" => "Adapters::ContentStore",
      )
    end

    it "does send draft content to the draft content store" do
      expect(DownstreamDraftJob).to receive(:perform_async).with(
        a_hash_including(
          "content_id",
        ),
      )

      described_class.new.perform(
        "content_id" => draft_edition.content_id,
        "content_store" => "Adapters::DraftContentStore",
      )
    end
  end
end
