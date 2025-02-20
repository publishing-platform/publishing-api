require "rails_helper"

RSpec.describe Presenters::DetailsPresenter do
  describe ".details" do
    let(:change_history_presenter) do
      instance_double(Presenters::ChangeHistoryPresenter, change_history: [])
    end

    subject do
      described_class.new(edition_details, change_history_presenter).details
    end

    context "when we're passed details without a body" do
      let(:edition_details) { {} }

      it "matches original details" do
        is_expected.to match(edition_details)
      end
    end

    context "without a change history presenter" do
      let(:change_history_presenter) { nil }
      let(:edition_details) do
        { body: "Without change history" }
      end

      it "matches original details" do
        is_expected.to match(edition_details)
      end
    end

    context "when we're passed a body which isn't enumerable" do
      let(:edition_details) do
        {
          body: "Something about VAT",
        }
      end

      it "matches original details" do
        is_expected.to match(edition_details)
      end
    end

    context "when we're passed details with markdown and HTML" do
      let(:edition_details) do
        {
          body: [
            { content_type: "text/html", content: "<strong>html</strong>" },
            { content_type: "text/markdown", content: "**html**" },
          ],
        }
      end

      it "matches original details" do
        is_expected.to match(edition_details)
      end
    end

    context "when we're passed markdown without HTML" do
      let(:edition_details) do
        {
          body: [
            { content_type: "text/markdown", content: "**hello**" },
          ],
        }
      end

      let(:expected_result) do
        {
          body: [
            { content_type: "text/markdown", content: "**hello**" },
            { content_type: "text/html", content: "<p><strong>hello</strong></p>\n" },
          ],
        }
      end

      it { is_expected.to match(expected_result) }
    end

    context "when we're passed multiple markdown fields" do
      let(:edition_details) do
        {
          body: [
            { content_type: "text/markdown", content: "**hello**" },
          ],
          other: [
            { content_type: "text/markdown", content: "**goodbye**" },
          ],

        }
      end

      let(:expected_result) do
        {
          body: [
            { content_type: "text/markdown", content: "**hello**" },
            { content_type: "text/html", content: "<p><strong>hello</strong></p>\n" },
          ],
          other: [
            { content_type: "text/markdown", content: "**goodbye**" },
            { content_type: "text/html", content: "<p><strong>goodbye</strong></p>\n" },
          ],
        }
      end

      it { is_expected.to match(expected_result) }
    end

    context "when we're passed an image hash" do
      let(:edition_details) do
        { image: { content_type: "image/png", content: "some content" } }
      end

      it "doesn't wrap the hash in an array" do
        expect(subject).to eq edition_details
      end
    end

    context "value contains nested array" do
      let(:edition_details) { { other: %w[an array of strings] } }
      it "doesn't try to convert from markdown" do
        expect { subject }.to_not raise_error
      end
    end

    context "when we're passed a deeply-nested hash with markdown" do
      let(:edition_details) do
        {
          parts: [
            {
              body: [
                {
                  content_type: "text/markdown",
                  content: "foo",
                },
              ],
            },
          ],
        }
      end

      let(:expected_details) do
        {
          parts: [
            {
              body: [
                {
                  content_type: "text/markdown",
                  content: "foo",
                },
                {
                  content_type: "text/html",
                  content: "<p>foo</p>\n",
                },
              ],
            },
          ],
        }
      end

      it "converts from markdown appropriately" do
        expect(subject).to eq expected_details
      end
    end
  end
end
