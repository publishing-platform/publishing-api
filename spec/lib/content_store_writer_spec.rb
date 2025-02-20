require "rails_helper"

RSpec.describe ContentStoreWriter do
  let(:content_store_host) { "http://content-store.example.com" }
  let(:content_store_writer) { ContentStoreWriter.new(content_store_host) }
  let(:base_path) { "/test/item" }

  let(:content_item) do
    {
      base_path:,
      details: {
        etc: %w[one two three],
      },
    }
  end

  describe "#put_content_item" do
    it "writes the content item as JSON to the given content store" do
      put_request = stub_request(:put, "#{content_store_host}/content#{base_path}")
        .with(body: content_item.to_json)

      content_store_writer.put_content_item(
        base_path:,
        content_item:,
      )

      expect(put_request).to have_been_requested
    end
  end

  describe "#delete_content_item" do
    it "writes the content item as JSON to the given content store" do
      delete_request = stub_request(:delete, "#{content_store_host}/content#{base_path}")

      content_store_writer.delete_content_item(base_path)

      expect(delete_request).to have_been_requested
    end
  end
end
