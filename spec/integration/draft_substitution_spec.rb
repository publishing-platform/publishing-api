require "rails_helper"

RSpec.describe "Substituting content that is not published" do
  let(:put_content_command) { Commands::PutContent }

  let(:content_id) { SecureRandom.uuid }
  let(:another_content_id) { SecureRandom.uuid }

  let(:payload) do
    {
      content_id:,
      base_path: "/vat-rates",
      title: "Some Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      document_type: "nonexistent-schema",
      schema_name: "nonexistent-schema",
      routes: [{ path: "/vat-rates", type: "exact" }],
      redirects: [],
      phase: "beta",
      update_type: "minor",
    }
  end

  let(:gone_base_path) { "/vat-rates" }

  let(:gone_payload) do
    {
      content_id: another_content_id,
      base_path: gone_base_path,
      document_type: "gone",
      schema_name: "gone",
      publishing_app: "publisher",
      routes: [{ path: gone_base_path, type: "exact" }],
      update_type: "minor",
    }
  end

  let(:validator) do
    instance_double(SchemaValidator, valid?: true, errors: [])
  end

  before do
    allow(SchemaValidator).to receive(:new).and_return(validator)
    stub_request(:any, /content-store/)
  end

  describe "after the first substitution" do
    before do
      put_content_command.call(payload)
      put_content_command.call(gone_payload)
    end

    it "discards the guide" do
      expect(Edition.count).to eq(1)

      edition = Edition.first

      expect(edition.document_type).to eq("gone")
      expect(edition.state).to eq("draft")
    end

    describe "after the second substitution" do
      before do
        put_content_command.call(payload)
      end

      it "discards the gone" do
        expect(Edition.count).to eq(1)

        edition = Edition.first

        expect(edition.document_type).to eq("nonexistent-schema")
        expect(edition.state).to eq("draft")
      end

      describe "after the third substitution" do
        before do
          put_content_command.call(gone_payload)
        end

        it "discards the guide" do
          expect(Edition.count).to eq(1)

          edition = Edition.first

          expect(edition.document_type).to eq("gone")
          expect(edition.state).to eq("draft")
        end
      end
    end
  end
end
