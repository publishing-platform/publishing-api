require "rails_helper"

RSpec.describe Queries::ContentDependencies do
  include DependencyResolutionHelper

  let(:content_id) { SecureRandom.uuid }
  let(:content_stores) { %w[live] }

  describe "#call" do
    subject do
      described_class.new(
        content_id:,
        content_stores:,
      ).call
    end

    context "when there are no links" do
      it { is_expected.to be_empty }
    end

    context "when items link to this edition" do
      before do
        create_edition(link_1_content_id, "/link-1")
        create_edition(link_2_content_id, "/link-2")
        create_link(link_1_content_id, content_id, "organisation")
        create_link(link_2_content_id, content_id, "organisation")
      end

      let(:link_1_content_id) { SecureRandom.uuid }
      let(:link_2_content_id) { SecureRandom.uuid }
      let(:links) do
        [
          link_1_content_id,
          link_2_content_id,
        ]
      end

      it { is_expected.to match_array(links) }
    end

    context "when items in different states link to this edition" do
      before do
        create_edition(link_1_content_id, "/link")
        create_edition(link_2_content_id, "/link", factory: :draft_edition)
        create_link(link_1_content_id, content_id, "organisation")
        create_link(link_2_content_id, content_id, "organisation")
      end

      let(:link_1_content_id) { SecureRandom.uuid }
      let(:link_2_content_id) { SecureRandom.uuid }
      let(:links) do
        [
          link_1_content_id,
        ]
      end

      it { is_expected.to match_array(links) }

      context "and we include drafts" do
        let(:content_stores) { %w[draft live] }

        let(:links) do
          [
            link_1_content_id,
            link_2_content_id,
          ]
        end

        it { is_expected.to match_array(links) }
      end
    end

    context "when a graph of parent items link to this edition" do
      before do
        create_edition(great_grandparent_content_id, "/great")
        create_edition(grandparent_content_id, "/great/grand")
        create_edition(parent_content_id, "/great/grand/parent")
        create_link(parent_content_id, content_id, "parent")
        create_link(grandparent_content_id, parent_content_id, "parent")
        create_link(great_grandparent_content_id, grandparent_content_id, "parent")
      end

      let(:great_grandparent_content_id) { SecureRandom.uuid }
      let(:grandparent_content_id) { SecureRandom.uuid }
      let(:parent_content_id) { SecureRandom.uuid }
      let(:links) do
        [
          great_grandparent_content_id,
          grandparent_content_id,
          parent_content_id,
        ]
      end

      it { is_expected.to match_array(links) }
    end

    context "when this edition has a link to an item with a reverse link type" do
      before do
        create_edition(reverse_link_content_id, "/reverse")
        create_link(content_id, reverse_link_content_id, "parent")
      end

      let(:reverse_link_content_id) { SecureRandom.uuid }
      let(:links) do
        [
          reverse_link_content_id,
        ]
      end

      it { is_expected.to match_array(links) }
    end

    context "when this content has a link to a draft item with a reverse link type" do
      before do
        create_edition(reverse_link_content_id, "/reverse", factory: :draft_edition)
        create_link(content_id, reverse_link_content_id, "parent")
      end

      let(:reverse_link_content_id) { SecureRandom.uuid }
      let(:content_stores) { %w[live] }

      it { is_expected.to be_empty }

      context "and we allow drafts" do
        let(:content_stores) { %w[draft live] }

        let(:links) do
          [
            reverse_link_content_id,
          ]
        end

        it { is_expected.to match_array(links) }
      end
    end
  end
end
