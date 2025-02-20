require "rails_helper"

RSpec.describe LinkExpansion::LinkReference do
  describe "#valid_link_node?" do
    let(:node) { double(:node, link_types_path:) }
    subject { described_class.new.valid_link_node?(node) }

    context "a single item in link_types_path" do
      let(:link_types_path) { [:anything] }
      it { is_expected.to be true }
    end

    context "a valid multi item link_types_path" do
      let(:link_types_path) { %i[parent parent] }
      it { is_expected.to be true }
    end

    context "an invalid multi item link_types_path" do
      let(:link_types_path) { %i[children parent] }
      it { is_expected.to be false }
    end
  end
end
