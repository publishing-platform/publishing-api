require "rails_helper"

RSpec.describe "Dependency Resolution" do
  include DependencyResolutionHelper

  subject(:dependency_resolution) do
    DependencyResolution.new(
      content_id,
      with_drafts:,
    ).dependencies
  end

  let(:content_id) { SecureRandom.uuid }
  let(:with_drafts) { true }

  context "when there are no links" do
    it "finds no dependencies" do
      expect(dependency_resolution).to be_empty
    end
  end

  context "when there are links from this content_id to another one, but not a link back" do
    before { create_link_set(content_id, links_hash: { organisation: [SecureRandom.uuid] }) }

    it "finds no dependencies" do
      expect(dependency_resolution).to be_empty
    end
  end

  context "when there are links to the contend_id" do
    let(:links_to_content_id) { SecureRandom.uuid }
    let(:linked_to) { [links_to_content_id] }
    before { create_link_set(links_to_content_id, links_hash: { organistion: [content_id] }) }

    it "has a dependency" do
      expect(dependency_resolution).to match_array([links_to_content_id])
    end
  end

  context "when an item links to an item that links to the content_id" do
    let(:a) { SecureRandom.uuid }
    let(:b) { SecureRandom.uuid }
    let(:link_type) { :organisation }

    before do
      create_link_set(a, links_hash: { link_type => [content_id] })
      create_link_set(b, links_hash: { link_type => [a] })
    end

    it "has a dependency only to the direct link" do
      expect(dependency_resolution).to match_array([a])
    end

    context "and the link_type is recursive" do
      let(:link_type) { :parent }

      it "has a dependency to both items" do
        expect(dependency_resolution).to match_array([a, b])
      end
    end
  end

  context "when there is an edition that has an edition link to content_id" do
    let(:edition_content_id) { SecureRandom.uuid }
    let(:link_type) { :organistion }
    before do
      create_edition(
        edition_content_id,
        "/edition-links",
        factory: edition_factory,
        links_hash: { link_type => [content_id] },
      )
    end

    context "and the edition is a draft" do
      let(:edition_factory) { :draft_edition }
      context "and we're including drafts" do
        let(:with_drafts) { true }
        it "has a dependency of the edition" do
          expect(dependency_resolution).to match_array([edition_content_id])
        end
      end

      context "but we aren't including drafts" do
        let(:with_drafts) { false }
        it "does not have a dependency of the edition" do
          expect(dependency_resolution).to be_empty
        end
      end
    end

    context "and the edition is superseded" do
      let(:edition_factory) { :superseded_edition }

      it "does not have a dependency of the edition" do
        expect(dependency_resolution).to be_empty
      end
    end

    context "and there is also a link of the same link_type in a link set" do
      let(:links_to_content_id) { SecureRandom.uuid }
      let(:edition_factory) { :live_edition }

      before do
        create_link_set(
          links_to_content_id,
          links_hash: { link_type => [content_id] },
        )
      end

      it "merges the links to return both" do
        expect(dependency_resolution).to match_array([edition_content_id, links_to_content_id])
      end
    end
  end

  context "when an edition links to an item that links to the content_id with a recursive link type" do
    let(:link_content_id) { SecureRandom.uuid }
    let(:edition_content_id) { SecureRandom.uuid }
    let(:link_type) { :parent_taxons }

    before do
      create_link_set(link_content_id, links_hash: { link_type => [content_id] })
      create_edition(
        edition_content_id,
        "/edition-links",
        links_hash: { link_type => [link_content_id] },
      )
    end

    it "only has a dependency of the link as recusive edition links aren't supported" do
      expect(dependency_resolution).to match_array([link_content_id])
    end
  end
end
