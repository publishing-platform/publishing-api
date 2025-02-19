require "rails_helper"

RSpec.describe Commands::ReservePath do
  describe "call" do
    let(:payload) do
      { base_path: "/foo", publishing_app: "Foo" }
    end

    context "with a new base_path" do
      it "successfully reserves the path" do
        expect(PathReservation).to receive(:reserve_base_path!)
          .with("/foo", "Foo")
        expect(described_class.call(payload)).to be_a Commands::Success
      end
    end

    context "with an invalid payload" do
      it "raises a CommandError" do
        expect {
          described_class.call({ base_path: "///" })
        }.to raise_error CommandError
      end
    end

    context "with base_path already reserved by another publishing app" do
      let(:payload) do
        { base_path: "/foo", publishing_app: "Bar" }
      end
      it "raises a CommandError" do
        create(:path_reservation, base_path: "/foo", publishing_app: "Foo")
        expect {
          described_class.call(payload)
        }.to raise_error CommandError
      end
    end

    context "with base_path already reserved by the same publishing app" do
      let(:payload) do
        { base_path: "/foo", publishing_app: "Foo" }
      end
      it "successfully reserves the path" do
        create(:path_reservation, base_path: "/foo", publishing_app: "Foo")
        expect(described_class.call(payload)).to be_a Commands::Success
      end
    end
  end
end
