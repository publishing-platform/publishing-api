require "rails_helper"

RSpec.describe Commands::RepresentDownstream do
  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  describe "call" do
    before do
      2.times { create(:draft_edition) }
      create(
        :live_edition,
        document: create(:document),
        document_type: "nonexistent-schema",
      )
      create(
        :live_edition,
        document: create(:document),
        document_type: "nonexistent-schema",
      )
      create(:live_edition, document_type: "press_release")
    end

    context "downstream live" do
      it "sends to downstream live worker" do
        expect(DownstreamLiveJob).to receive(:perform_async)
          .exactly(3).times
        subject.call(Document.pluck(:content_id), with_drafts: false)
      end

      it "doesn't update dependencies" do
        expect(DownstreamLiveJob).to receive(:perform_async)
          .with(a_hash_including("update_dependencies" => false))
          .at_least(1).times
        subject.call(Document.pluck(:content_id), with_drafts: false)
      end

      it "has a message_queue_event_type of 'links'" do
        expect(DownstreamLiveJob).to receive(:perform_async)
          .with(a_hash_including("message_queue_event_type" => "links"))
          .at_least(1).times
        subject.call(Document.pluck(:content_id), with_drafts: false)
      end

      it "has a source_command of 'represent_downstream'" do
        expect(DownstreamLiveJob).to receive(:perform_async)
          .with(a_hash_including("source_command" => "represent_downstream"))
          .at_least(1).times
        subject.call(Document.pluck(:content_id), with_drafts: false)
      end
    end

    context "scope" do
      it "can specify a scope" do
        expect(DownstreamLiveJob).to receive(:perform_async)
          .with(a_hash_including("content_id"))
          .exactly(2).times
        subject.call(
          Edition.with_document.where(document_type: "nonexistent-schema").pluck("documents.content_id"),
          with_drafts: false,
        )
      end
    end

    context "drafts optional" do
      it "can send to downstream draft worker" do
        expect(DownstreamDraftJob).to receive(:perform_async)
          .with(
            a_hash_including("content_id", "update_dependencies" => false),
          )
          .exactly(5).times
        subject.call(Document.pluck(:content_id), with_drafts: true)
      end

      it "can not send to downstream draft worker" do
        expect(DownstreamDraftJob).to_not receive(:perform_async)
        subject.call(Document.pluck(:content_id), with_drafts: false)
      end
    end
  end
end
