require "publishing_platform_markdown"

module Presenters
  class DetailsPresenter
    attr_reader :content_item_details, :change_history_presenter

    def initialize(content_item_details, change_history_presenter)
      @content_item_details = SymbolizeJson.symbolize(content_item_details)
      @change_history_presenter = change_history_presenter
    end

    def details
      @details ||=
        begin
          updated = recursively_transform_markdown(content_item_details)
          updated[:change_history] = change_history if change_history.present?
          updated
        end
    end

  private

    def markdown_content?(value)
      wrapped = Array.wrap(value)
      wrapped.all? { |hsh| hsh.is_a?(Hash) } &&
        wrapped.one? { |hsh| hsh[:content_type] == "text/markdown" } &&
        wrapped.none? { |hsh| hsh[:content_type] == "text/html" }
    end

    def html_content?(value)
      wrapped = Array.wrap(value)
      wrapped.all? { |hsh| hsh.is_a?(Hash) } &&
        wrapped.one? { |hsh| hsh[:content_type] == "text/html" }
    end

    def recursively_transform_markdown(obj)
      return obj if !obj.respond_to?(:map) || html_content?(obj)
      return render_markdown(obj) if markdown_content?(obj)

      if obj.is_a?(Hash)
        obj.transform_values do |value|
          recursively_transform_markdown(value)
        end
      else
        obj.map { |o| recursively_transform_markdown(o) }
      end
    end

    def change_history
      @change_history ||= change_history_presenter&.change_history
    end

    def render_markdown(value)
      wrapped_value = Array.wrap(value)
      html = {
        content_type: "text/html",
        content: rendered_markdown(wrapped_value),
      }
      wrapped_value + [html]
    end

    def rendered_markdown(value)
      PublishingPlatformMarkdown::Document.new(raw_markdown(value), markdown_attributes).to_html
    end

    def raw_markdown(value)
      value.find { |format| format[:content_type] == "text/markdown" }[:content]
    end

    def markdown_attributes
      {
        attachments: content_item_details[:attachments],
      }
    end
  end
end
