require "rails_helper"

RSpec.describe Commands::PatchLinkSet do
  let(:expected_content_store_payload) { { base_path: "/vat-rates" } }
  let(:content_id) { SecureRandom.uuid }
  let!(:document) { create(:document, content_id:) }
  let!(:draft_edition) do
    create(:edition,
           document:,
           base_path: "/some-path",
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

  let(:action_payload) { payload }
  let(:action) { "PatchLinkSet" }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})

    allow_any_instance_of(Presenters::EditionPresenter)
      .to receive(:for_content_store)
      .and_return(expected_content_store_payload)
  end

  include_examples "creates an action"

  context "when no link set exists" do
    it "creates the link set and associated links" do
      described_class.call(payload)

      link_set = LinkSet.last
      expect(link_set).to be_present
      expect(link_set.content_id).to eq(content_id)

      links = link_set.links
      expect(links.map(&:link_type)).to eq(%w[parent primary_publishing_organisation])
      expect(links.map(&:target_content_id)).to eq(parent + primary_publishing_organisation)
    end

    it "doesn't reject an empty links hash, but doesn't delete links either" do
      link_set = create(
        :link_set,
        content_id:,
        links: [
          create(:link),
        ],
      )

      described_class.call(
        {
          content_id: link_set.content_id,
          links: {},
        },
      )

      expect(link_set.links.count).to eql(1)
    end

    it "creates a lock version for the link set" do
      described_class.call(payload)

      link_set = LinkSet.last
      expect(link_set).to be_present
      expect(link_set.stale_lock_version).to eq(1)
    end

    it "responds with a success object containing the newly created links in the same order as in the request" do
      result = described_class.call(payload)

      expect(result).to be_a(Commands::Success)
      expect(result.data).to eq(
        content_id:,
        version: 1,
        links: {
          primary_publishing_organisation:,
          parent:,
        },
      )
    end
  end

  context "when a link set exists" do
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

    it "creates links for groups that appear in the payload and not in the database" do
      described_class.call(payload)

      link_set = LinkSet.last
      links = link_set.links

      parent_links = links.where(link_type: "parent")
      expect(parent_links.map(&:target_content_id)).to eq(parent)
    end

    it "updates links for groups that appear in the payload and in the database" do
      updated_link = [SecureRandom.uuid]

      described_class.call({
        content_id:,
        links: {
          primary_publishing_organisation: updated_link,
        },
      })

      link_set = LinkSet.last
      links = link_set.links

      org_links = links.where(link_type: "primary_publishing_organisation")
      expect(org_links.map(&:target_content_id)).to eq(updated_link)
    end

    it "does not affect links for groups that do not appear in the payload" do
      described_class.call({
        content_id:,
        links: {
          parent:,
        },
      })

      link_set = LinkSet.last
      links = link_set.links

      related_links = links.where(link_type: "primary_publishing_organisation")
      expect(related_links.map(&:target_content_id)).to eq(primary_publishing_organisation)
    end

    it "increments the lock version for the link set" do
      described_class.call(payload)

      link_set = LinkSet.last
      expect(link_set).to be_present
      expect(link_set.stale_lock_version).to eq(2)
    end

    it "responds with a success object containing the updated links in the same order as in the request" do
      result = described_class.call(payload)

      expect(result).to be_a(Commands::Success)
      expect(result.data).to eq(
        content_id:,
        version: 2,
        links: {
          primary_publishing_organisation:,
          parent:,
        },
      )
    end

    context "with a 'previous_version' that matches the lock version" do
      before do
        payload[:previous_version] = 1
      end

      it "does not raise an error" do
        expect {
          described_class.call(payload)
        }.not_to raise_error
      end
    end

    context "with a 'previous_version' that does not match the lock version" do
      before do
        payload[:previous_version] = 2
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /Conflict/)
      end
    end
  end

  context "when a draft edition exists for the content_id" do
    it "sends to the downstream draft worker" do
      expect(DownstreamDraftJob).to receive(:perform_async)
        .with(
          a_hash_including("content_id", "update_dependencies" => true),
        )

      described_class.call(payload)
    end

    it "sends to the downstream draft worker without updating dependencies if it hasn't changed" do
      expect(DownstreamDraftJob).to receive(:perform_async)
        .with(a_hash_including("update_dependencies" => true))

      described_class.call(payload)

      expect(DownstreamDraftJob).to receive(:perform_async)
        .with(a_hash_including("update_dependencies" => false))

      described_class.call(payload)
    end

    context "when 'downstream' is false" do
      it "does not send a request to either content store" do
        expect(DownstreamDraftJob).not_to receive(:perform_async)
        expect(DownstreamLiveJob).not_to receive(:perform_async)
        described_class.call(payload, downstream: false)
      end
    end
  end

  context "when a live edition exists for the content_id" do
    before do
      draft_edition.destroy!

      create(
        :live_edition,
        document:,
        base_path: "/some-path",
        title: "Some Title",
      )
    end

    it "sends to downstream live worker" do
      expect(DownstreamLiveJob).to receive(:perform_async)
        .with(
          a_hash_including(
            "content_id",
            "message_queue_event_type" => "links",
            "update_dependencies" => true,
          ),
        )

      described_class.call(payload)
    end

    it "sends to the downstream live worker without updating dependencies if it hasn't changed" do
      expect(DownstreamLiveJob).to receive(:perform_async)
        .with(a_hash_including("update_dependencies" => true))

      described_class.call(payload)

      expect(DownstreamLiveJob).to receive(:perform_async)
        .with(a_hash_including("update_dependencies" => false))

      described_class.call(payload)
    end

    context "when 'downstream' is false" do
      it "does not send a request to presented content store worker" do
        expect(DownstreamDraftJob).not_to receive(:perform_async)
        described_class.call(payload, downstream: false)
      end

      it "does not send a request to downstream live worker" do
        expect(DownstreamLiveJob).not_to receive(:perform_async)
        described_class.call(payload, downstream: false)
      end
    end
  end

  context "when an unpublished edition exists for the content_id" do
    before do
      draft_edition.destroy!

      create(
        :unpublished_edition,
        document:,
        base_path: "/some-path",
        title: "Some Title",
      )
    end

    it "sends to downstream draft worker" do
      expect(DownstreamDraftJob).to receive(:perform_async)
        .with(a_hash_including("content_id"))

      described_class.call(payload)
    end

    it "sends to downstream live worker" do
      expect(DownstreamLiveJob).to receive(:perform_async)
        .with(
          a_hash_including(
            "content_id",
            "message_queue_event_type" => "links",
          ),
        )

      described_class.call(payload)
    end
  end

  context "when 'links' are replaced in the payload" do
    let(:link_a) { SecureRandom.uuid }
    let(:link_b) { SecureRandom.uuid }

    let(:payload) do
      { content_id:, links: { primary_publishing_organisation: [link_b] } }
    end

    before do
      draft_edition.destroy!

      create(
        :live_edition,
        document:,
        base_path: "/some-path",
        title: "Some Title",
      )

      create(
        :link_set,
        content_id:,
        links_hash: { primary_publishing_organisation: [link_a] },
      )
    end

    it "sends link_a downstream as an orphaned content_id when replaced by link_b" do
      expect(DownstreamLiveJob).to receive(:perform_async)
        .with(a_hash_including("orphaned_content_ids" => [link_a]))

      described_class.call(payload)
    end
  end

  context "when 'links' is missing from the payload" do
    before do
      payload.delete(:links)
    end

    it "raises a command error" do
      expect {
        described_class.call(payload)
      }.to raise_error(CommandError, "Links are required")
    end
  end

  context "when 'links' is nil in the payload" do
    before do
      payload[:links] = nil
    end

    it "raises a command error" do
      expect {
        described_class.call(payload)
      }.to raise_error(CommandError, "Links are required")
    end
  end

  context "when payload does not conform to schema" do
    before do
      payload[:links][:invalid_link_type] = [SecureRandom.uuid]
    end

    it "raises a command error" do
      expect {
        described_class.call(payload)
      }.to raise_error(CommandError, "The payload did not conform to the schema")
    end
  end

  it_behaves_like TransactionalCommand
end
