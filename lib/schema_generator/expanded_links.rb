module SchemaGenerator
  class ExpandedLinks
    LINK_TYPES_ADDED_BY_PUBLISHING_API = {
      # Content items that are linked to with a `parent` link type will automatically
      # have a `children` link type with those items.
      "children" => "frontend_links_with_base_path",
    }.freeze

    def initialize(format)
      @format = format
    end

    def generate
      {
        type: "object",
        additionalProperties: false,
        properties: links,
      }
    end

  private

    attr_reader :format

    def links
      links = publishing_api_links.merge(content_links).merge(edition_links)
      Hash[links.sort]
    end

    def publishing_api_links
      LINK_TYPES_ADDED_BY_PUBLISHING_API.transform_values do |definition|
        {
          "description" => "Link type automatically added by Publishing API",
          "$ref": "#/definitions/#{definition}",
        }
      end
    end

    def content_links
      format.content_links.frontend_properties
    end

    def edition_links
      format.edition_links.frontend_properties
    end
  end
end