require "rails_helper"

RSpec.describe "/linkables", type: :request do
  let(:request_path) { "/linkables" }

  let!(:org_1) do
    create(
      :edition,
      document_type: "organisation",
      schema_name: "organisation",
      title: "Organisation 1",
      base_path: "/organisation-1",
      details: {
        internal_name: "An internal name",
      },
    )
  end

  let!(:org_2) do
    create(
      :live_edition,
      document_type: "organisation",
      schema_name: "organisation",
      title: "Organisation 2",
      base_path: "/organisation-2",
    )
  end

  it "returns the title, content ID, state, internal name and base path for all editions of a given format" do
    get request_path, params: { document_type: "organisation" }

    expect(JSON.parse(response.body, symbolize_names: true)).to match_array([
      hash_including(
        content_id: org_1.document.content_id,
        title: "Organisation 1",
        publication_state: "draft",
        base_path: "/organisation-1",
        internal_name: "An internal name",
      ),
      hash_including(
        content_id: org_2.document.content_id,
        title: "Organisation 2",
        publication_state: "published",
        base_path: "/organisation-2",
        internal_name: "Organisation 2",
      ),
    ])
  end

  context "without a format" do
    it "422s" do
      get request_path

      expect(response.status).to eq(422)
    end
  end
end
