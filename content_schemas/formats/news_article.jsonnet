(import "shared/default_format.jsonnet") + {
  document_type: [
    "press_release",
    "news_story",
  ],
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
      ],      
      properties: {
        attachments: {
          description: "An ordered list of asset links",
          type: "array",
          items: {
            "$ref": "#/definitions/file_attachment_asset",
          },
        },        
        body: {
          "$ref": "#/definitions/body_html_and_markdown",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },  
        image: {
          "$ref": "#/definitions/image_asset",
        },                
      },
    },  
  },  
  edition_links: (import "shared/base_edition_links.jsonnet") + {
    parent: {
      description: "The parent content item.",
      maxItems: 1,
    }, 
    primary_publishing_organisation: {
      description: "The organisation that published the page.",
      maxItems: 1,
    },      
  }
}