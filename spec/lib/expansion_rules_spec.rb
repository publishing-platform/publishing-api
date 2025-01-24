require "rails_helper"

RSpec.describe ExpansionRules do
  subject(:rules) { described_class }

  describe ".reverse_link_type" do
    specify { expect(rules.reverse_link_type(:parent)).to be(:children) }
    specify { expect(rules.reverse_link_type(:children)).to be_nil }
    specify { expect(rules.reverse_link_type(:made_up)).to be_nil }
  end

  describe ".reverse_to_direct_link_type" do
    specify { expect(rules.reverse_to_direct_link_type(:children)).to match_array(%i[parent]) }
    specify { expect(rules.reverse_to_direct_link_type(:parent)).to be_empty }
    specify { expect(rules.reverse_to_direct_link_type(:made_up)).to be_empty }
  end

  describe ".is_reverse_link_type?" do
    specify { expect(rules.is_reverse_link_type?(:children)).to be(true) }
    specify { expect(rules.is_reverse_link_type?(:parent)).to be(false) }
    specify { expect(rules.is_reverse_link_type?(:made_up)).to be(false) }
  end

  describe ".reverse_to_direct_link_types" do
    specify do
      expect(rules.reverse_to_direct_link_types(%i[children documents]))
        .to match([:parent])
    end

    specify { expect(rules.reverse_to_direct_link_types([:made_up])).to match([]) }
  end

  describe ".reverse_link_types_hash" do
    let(:content_ids) { %w[a b] }

    specify do
      expect(rules.reverse_link_types_hash(parent: content_ids))
        .to match(children: content_ids)
      expect(rules.reverse_link_types_hash(policies: content_ids)).to match({})
    end
  end

  describe ".expansion_fields" do
    let(:default_fields) { rules::DEFAULT_FIELDS }
    let(:organisation_fields) { default_fields - [:public_updated_at] + [%i[details abbreviation], %i[details status]] }
    let(:default_fields_and_description) { default_fields + %i[description] }

    specify { expect(rules.expansion_fields(:redirect)).to eq([]) }
    specify { expect(rules.expansion_fields(:gone)).to eq([]) }

    specify { expect(rules.expansion_fields(:parent)).to eq(default_fields) }

    specify { expect(rules.expansion_fields(:organisation)).to eq(organisation_fields) }

    specify { expect(rules.expansion_fields(:parent, link_type: :finder)).to eq(default_fields) }
  end

  describe ".expansion_fields_for_document_type" do
    before do
      stub_const(
        "ExpansionRules::CUSTOM_EXPANSION_FIELDS",
        [
          { document_type: :news, fields: %i[news_a] },
          { document_type: :news,
            link_type: :breaking_news,
            fields: %i[news_a news_b] },
          { document_type: :news,
            link_type: :local_news,
            fields: %i[news_c news_d] },
        ],
      )
    end

    it "returns default fields when a document type doesn't have any custom entries" do
      expect(rules.expansion_fields_for_document_type(:other_type))
        .to match_array(ExpansionRules::DEFAULT_FIELDS)
    end

    it "can accept a string instead of a symbol" do
      from_symbol = rules.expansion_fields_for_document_type(:news)
      from_string = rules.expansion_fields_for_document_type("news")
      expect(from_symbol).to eq(from_string)
    end

    it "collates all the fields used by links for the document type" do
      expect(rules.expansion_fields_for_document_type(:news))
        .to match_array(%i[news_a news_b news_c news_d])
    end

    context "when a custom fields entry only has examples with links" do
      before do
        stub_const(
          "ExpansionRules::CUSTOM_EXPANSION_FIELDS",
          [
            { document_type: :editorial,
              link_type: :current_events,
              fields: %i[editorial_a] },
            { document_type: :editorial,
              link_type: :world_events,
              fields: %i[editorial_b] },
          ],
        )
      end

      it "includes default fields as expansion fields" do
        expect(rules.expansion_fields_for_document_type(:editorial))
          .to contain_exactly(:editorial_a, :editorial_b, *ExpansionRules::DEFAULT_FIELDS)
      end
    end
  end

  describe ".expansion_fields_for_linked_document_type" do
    before do
      stub_const(
        "ExpansionRules::CUSTOM_EXPANSION_FIELDS",
        [
          { document_type: :news, fields: %i[news_a] },
          { document_type: :news,
            link_type: :breaking_news,
            fields: %i[news_a news_b] },
          { document_type: :editorial,
            link_type: :current_events,
            fields: %i[editorial_a] },
        ],
      )
    end

    it "can accept strings instead of symbols" do
      from_symbols = rules.expansion_fields_for_linked_document_type(:news, :breaking_news)
      from_strings = rules.expansion_fields_for_linked_document_type("news", "breaking_news")
      expect(from_symbols).to eq(from_strings)
    end

    it "returns default fields when a document type doesn't have any custom entries" do
      expect(rules.expansion_fields_for_linked_document_type(:unknown_type, :unknown_link))
        .to match_array(ExpansionRules::DEFAULT_FIELDS)
    end

    it "returns default fields when a document type is only listed for specific links" do
      expect(rules.expansion_fields_for_linked_document_type(:editorial, :unknown_link))
        .to match_array(ExpansionRules::DEFAULT_FIELDS)
    end

    it "returns specified fields when document type and link type match" do
      expect(rules.expansion_fields_for_linked_document_type(:news, :breaking_news))
        .to match_array(%i[news_a news_b])
    end

    it "returns specified fields when link type is not matched but "\
      "document_type is defined without a link type" do
      expect(rules.expansion_fields_for_linked_document_type(:news, :unknown_type))
        .to match_array(%i[news_a])
    end
  end

  describe ".next_allowed_direct_link_types" do
    subject do
      described_class.next_allowed_direct_link_types(
        next_allowed_link_types, reverse_to_direct:
      )
    end

    before do
      stub_const(
        "ExpansionRules::REVERSE_LINKS",
        {
          parent: :children,
          person: :role_appointments,
          role: :role_appointments,
        },
      )
    end

    let(:reverse_to_direct) { false }

    context "when passed direct links only" do
      let(:next_allowed_link_types) do
        {
          parent: %i[parent parent_taxons],
        }
      end

      it "returns the links unchanged" do
        expect(subject).to match(next_allowed_link_types)
      end
    end

    context "when passed reverse links only" do
      let(:next_allowed_link_types) do
        {
          parent: [:children],
        }
      end

      it "returns an empty hash" do
        expect(subject).to be_empty
      end
    end

    context "when passed a mixture of direct and reverse links" do
      let(:next_allowed_link_types) do
        {
          parent: %i[children parent],
        }
      end

      it "returns the direct links" do
        expect(subject).to match(parent: [:parent])
      end
    end

    context "when passed a reverse link with direct links" do
      let(:next_allowed_link_types) do
        {
          children: [:parent],
        }
      end

      it "returns the direct links" do
        expect(subject).to match(children: [:parent])
      end
    end

    context "when reverse_to_direct is true and passed a reverse link with direct links" do
      let(:reverse_to_direct) { true }
      let(:next_allowed_link_types) do
        {
          children: [:parent],
        }
      end

      it "reverses the link type" do
        expect(subject).to match(parent: [:parent])
      end
    end

    context "when reverse_to_direct is true and passed a reverse link with multiple direct links" do
      let(:reverse_to_direct) { true }
      let(:next_allowed_link_types) do
        {
          role_appointments: [:other],
        }
      end

      it "reverses the link type" do
        expect(subject).to match(
          person: [:other],
          role: [:other],
        )
      end
    end
  end

  describe ".next_allowed_reverse_link_types" do
    subject do
      described_class.next_allowed_reverse_link_types(
        next_allowed_link_types,
        reverse_to_direct:,
      )
    end

    before do
      stub_const(
        "ExpansionRules::REVERSE_LINKS",
        {
          parent: :children,
          person: :role_appointments,
          role: :role_appointments,
        },
      )
    end

    let(:reverse_to_direct) { false }

    context "when passed direct links only" do
      let(:next_allowed_link_types) do
        {
          children: %i[parent parent_taxons],
        }
      end

      it "returns an empty hash" do
        expect(subject).to be_empty
      end
    end

    context "when passed reverse links only" do
      let(:next_allowed_link_types) do
        {
          children: [:children],
        }
      end

      it "returns the links unchanged" do
        expect(subject).to match(next_allowed_link_types)
      end
    end

    context "when passed a mixture of direct and reverse links" do
      let(:next_allowed_link_types) do
        {
          children: %i[children parent],
        }
      end

      it "returns the reverse links" do
        expect(subject).to match(children: [:children])
      end
    end

    context "when reverse_to_direct is true" do
      let(:next_allowed_link_types) do
        {
          children: [:children],
        }
      end
      let(:reverse_to_direct) { true }

      it "changes the link types to be their direct counterpart" do
        expect(subject).to match(parent: [:parent])
      end
    end

    context "when reverse_to_direct is true and passed a reverse link with multiple direct links" do
      let(:reverse_to_direct) { true }
      let(:next_allowed_link_types) do
        {
          other: [:role_appointments],
        }
      end

      it "changes the link types to be their direct counterpart" do
        expect(subject).to match(other: %i[person role])
      end
    end
  end

  describe "REVERSE_LINKS" do
    let(:reverse_links) { described_class.reverse_links.map(&:to_s) }

    describe "are defined in necessary frontend schemas" do
      schemas_of_type("frontend/schema").each do |path, schema|
        links = schema["properties"]["links"]
        next unless links

        context "when the schema is #{path}" do
          subject { links["properties"].keys }

          it { is_expected.to include(*reverse_links) }
        end
      end
    end

    describe "are not defined in publisher schemas" do
      schemas_of_type("publisher/links").each do |path, schema|
        links = schema["properties"]["links"]
        next unless links

        context "when the schema is #{path}" do
          subject { links["properties"].keys }

          it { is_expected.not_to include(*reverse_links) }
        end
      end
    end
  end

  describe ".expand_fields" do
    context "with a format that expands subfields of the details hash" do
      let(:edition_hash) do
        {
          document_type: "organisation",
          details: {
            organisation_type: "department",
            other_field: "test",
          },
        }
      end

      it "expands into a new details hash" do
        expect(described_class.expand_fields(edition_hash)).to eq(
          document_type: "organisation",
          details: {
            abbreviation: nil,
            status: nil,
          },
          api_path: nil,
          base_path: nil,
          content_id: nil,
          schema_name: nil,
          title: nil,
          withdrawn: nil,
        )
      end
    end
  end
end
