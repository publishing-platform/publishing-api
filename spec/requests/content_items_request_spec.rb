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

    context "with pagination params" do
      it "responds with the edition" do
        get "/content", params: { start: "0", page_size: "20" }

        expect(response.status).to eq(200)
        expect(parsed_response["results"].count).to eq(1)
        expect(parsed_response["results"][0]["base_path"]).to eq("/foo")
      end
    end

    context "with an order param" do
      let!(:other_edition) { create(:live_edition, base_path: "/bar") }

      before do
        edition.update!(
          updated_at: Date.new(2016, 1, 1),
          last_edited_at: Date.new(2016, 1, 1),
        )

        other_edition.update!(
          updated_at: Date.new(2016, 2, 2),
          last_edited_at: Date.new(2016, 2, 2),
        )

        get "/content", params: { order:, fields: }
      end

      context "when ordering by updated_at ascending" do
        let(:order) { "updated_at" }
        let(:fields) { %w[updated_at] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "updated_at" => "2016-01-01T00:00:00Z" },
            { "updated_at" => "2016-02-02T00:00:00Z" },
          ])
        end
      end

      context "when ordering by updated_at descending" do
        let(:order) { "-updated_at" }
        let(:fields) { %w[updated_at] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "updated_at" => "2016-02-02T00:00:00Z" },
            { "updated_at" => "2016-01-01T00:00:00Z" },
          ])
        end
      end

      context "when ordering by last_edited_at ascending" do
        let(:order) { "last_edited_at" }
        let(:fields) { %w[last_edited_at] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "last_edited_at" => "2016-01-01T00:00:00Z" },
            { "last_edited_at" => "2016-02-02T00:00:00Z" },
          ])
        end
      end

      context "when ordering by last_edited_at descending" do
        let(:order) { "-last_edited_at" }
        let(:fields) { %w[last_edited_at] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "last_edited_at" => "2016-02-02T00:00:00Z" },
            { "last_edited_at" => "2016-01-01T00:00:00Z" },
          ])
        end
      end

      context "when ordering by base_path ascending" do
        let(:order) { "base_path" }
        let(:fields) { %w[base_path] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "base_path" => "/bar" },
            { "base_path" => "/foo" },
          ])
        end
      end

      context "when ordering by base_path descending" do
        let(:order) { "-base_path" }
        let(:fields) { %w[base_path] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "base_path" => "/foo" },
            { "base_path" => "/bar" },
          ])
        end
      end

      context "when ordering by a field that doesn't exist" do
        let(:order) { "doesnt_exist" }
        let(:fields) { %w[content_id] }

        it "responds with 422 and an error message" do
          expect(response.status).to eq(422)
          message = parsed_response["error"]["message"]
          expect(message).to include(order)
        end
      end

      context "when ordering by a field without an index" do
        let(:order) { "created_at" }
        let(:fields) { %w[content_id] }

        it "responds with 422 and an error message" do
          expect(response.status).to eq(422)
          message = parsed_response["error"]["message"]
          expect(message).to include(order)
        end
      end

      context "ordering by updated_at when it's not selected" do
        let(:order) { "updated_at" }
        let(:fields) { %w[base_path] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "base_path" => "/foo" },
            { "base_path" => "/bar" },
          ])
        end
      end
    end
  end
end
