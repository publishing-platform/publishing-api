require "rails_helper"

RSpec.describe "/content", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:request_path) { "/links/#{content_id}" }

  describe "GET /index" do
    let(:previous_edition) do
      create(
        :superseded_edition,
        base_path: "/foo",
        title: "zip",
        user_facing_version: 1,
      )
    end
    let!(:edition) do
      create(
        :live_edition,
        base_path: "/foo",
        document: previous_edition.document,
        title: "bar",
        description: "stuff",
        user_facing_version: 2,
      )
    end

    context "searching a field" do
      context "when there is a valid query" do
        it "returns the item when searching for base_path" do
          get "/content", params: { q: "foo" }

          expect(response.status).to eq(200)
          expect(parsed_response["results"].count).to eq(1)
          expect(parsed_response["total"]).to eq(1)
          expect(parsed_response["pages"]).to eq(1)
          expect(parsed_response["current_page"]).to eq(1)
          expect(parsed_response["results"][0]["base_path"]).to eq("/foo")
        end

        it "returns the item when searching for title" do
          get "/content", params: { q: "bar" }

          expect(response.status).to eq(200)
          expect(parsed_response["results"].count).to eq(1)
          expect(parsed_response["total"]).to eq(1)
          expect(parsed_response["pages"]).to eq(1)
          expect(parsed_response["current_page"]).to eq(1)
          expect(parsed_response["results"][0]["base_path"]).to eq("/foo")
        end

        it "doesn't return items that are no longer the latest version" do
          get "/content", params: { q: "zip" }
          expect(response.status).to eq(200)
          expect(parsed_response["results"].count).to eq(0)
        end
      end

      context "specifying fields to search" do
        it "returns the item" do
          get "/content", params: { q: "stuff", search_in: %w[description] }

          expect(response.status).to eq(200)
          expect(parsed_response["results"][0]["base_path"]).to eq("/foo")
        end
      end
    end

    context "with a document_type param" do
      let!(:other_edition) do
        create(
          :live_edition,
          document_type: "organisation",
        )
      end

      it "filters by document type" do
        get "/content", params: { document_type: "answer" }

        expect(response.status).to eq(200)
        expect(parsed_response["results"].count).to eq(1)
        expect(parsed_response["results"][0]["base_path"]).to eq("/foo")
      end
    end
  end
end
