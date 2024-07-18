(import "shared/default_format.jsonnet") + {
  document_type: "answer",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        body: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },        
      },
    },
  },  
}