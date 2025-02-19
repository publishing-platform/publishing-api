require "rails_helper"

RSpec.describe "Rake tasks for publishing special routes" do
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  context "with special routes data" do
    let(:stdout) { double(:stdout, puts: nil) }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:replacement_special_routes_file) do
      YAML.load_file(Rails.root.join("spec/fixtures/special_routes.yaml"))
    end

    before do
      original_special_routes_path = Rails.root.join("lib/data/special_routes.yaml")
      allow(YAML).to receive(:load_file).with(original_special_routes_path).and_return(replacement_special_routes_file)
    end

    describe "special_routes:publish" do
      before do
        Rake::Task["special_routes:publish"].reenable
      end

      it "publishes the special routes, except the homepage" do
        Rake::Task["special_routes:publish"].invoke

        expect(Document.count).to eq(3)
        expect(Edition.count).to eq(3)
        expect(Edition.all.collect(&:title)).to eq(["Account home page", "Save a page", "Uploads"])
      end
    end

    describe "special_routes:publish_homepage" do
      before do
        Rake::Task["special_routes:publish_homepage"].reenable
      end

      it "publishes the homepage, and nothing else" do
        Rake::Task["special_routes:publish_homepage"].invoke

        expect(Document.count).to eq(1)
        expect(Edition.count).to eq(1)
        edition = Edition.where(title: "Publishing Platform homepage").first
        expect(edition).not_to be_nil
      end
    end
  end
end
