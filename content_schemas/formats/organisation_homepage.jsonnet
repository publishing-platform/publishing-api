(import "shared/default_format.jsonnet") + {
  document_type: "finder",
  edition_links: {},
  definitions: (import "shared/definitions/_organisations.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        ordered_departments: {
          "$ref": "#/definitions/summary_organisations",
        }         
      }
    }, 
  },     
}