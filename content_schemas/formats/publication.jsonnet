(import "shared/default_format.jsonnet") + {
  document_type: [
    "guidance",
    "statutory_guidance",
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
            "$ref": "#/definitions/publication_attachment_asset",
          },
        }, 
        featured_attachments: {
          description: "An ordered list of attachments to feature below the document",
          type: "array",
          uniqueItems: true,
          items: {
            type: "string",
          },
        },               
        body: {
          "$ref": "#/definitions/body_html_and_markdown",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
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