require "rails_helper"

RSpec.describe "/paths", type: :request do
  let(:base_path) { "/vat-rates" }
  let(:request_path) { "/paths#{base_path}" }

  describe "PUT /reserve_path" do
    let(:payload) do
      {
        publishing_app: "publisher",
      }
    end

    context "with path /vat-rates" do
      it "responds successfully" do
        put request_path, params: payload.to_json

        expect(response.status).to eq(200)
      end

      it "reserves a new path" do
        expect {
          put request_path, params: payload.to_json
        }.to change(PathReservation, :count).by(1)
      end

      context "and path is already reserved by another app" do
        before do
          create(:path_reservation, base_path:, publishing_app: "another")
        end

        it "responds with status 422 and appropriate error message" do
          expect {
            put request_path, params: payload.to_json
          }.not_to change(PathReservation, :count)

          expect(response.status).to eq(422)
          expect(parsed_response["error"]["message"]).to eq "Base path /vat-rates is already reserved by another"
        end
      end
    end

    context "with invalid payload" do
      let(:payload) do
        {
          publishing_app: nil,
        }
      end

      it "responds with status 422 and appropriate error message" do
        put request_path, params: payload.to_json

        expect(response.status).to eq(422)
        expect(parsed_response["error"]["message"]).to eq "Publishing app can't be blank"
      end

      it "does not reserve path" do
        expect {
          put request_path, params: payload.to_json
        }.not_to change(PathReservation, :count)
      end
    end
  end

  describe "DELETE /unreserve_path" do
    let(:payload) do
      {
        publishing_app: "publisher",
      }
    end

    before do
      create(
        :path_reservation,
        base_path:,
        publishing_app: "publisher",
      )
    end

    context "with a valid path unreservation request" do
      it "responds successfully" do
        delete request_path, params: payload.to_json

        expect(response.status).to eq(200)
      end

      it "unreserves path" do
        expect {
          delete request_path, params: payload.to_json
        }.to change(PathReservation, :count).by(-1)
      end
    end

    context "with a non-existant path unreservation request" do
      let(:invalid_request_path) { "/paths/non-existent" }
      it "responds with status 404" do
        delete invalid_request_path, params: payload.to_json

        expect(response.status).to eq(404)
      end

      it "does not unreserve path" do
        expect {
          delete invalid_request_path, params: payload.to_json
        }.not_to change(PathReservation, :count)
      end
    end

    context "with path reserved by another app" do
      let(:payload) do
        {
          publishing_app: "organisations-publisher",
        }
      end

      it "responds with status 422 and appropriate error message" do
        expect {
          delete request_path, params: payload.to_json
        }.not_to change(PathReservation, :count)

        expect(response.status).to eq(422)
        expect(parsed_response["error"]["message"]).to eq "/vat-rates is reserved by publisher"
      end
    end
  end
end
