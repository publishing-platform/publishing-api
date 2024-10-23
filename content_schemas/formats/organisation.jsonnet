(import "shared/default_format.jsonnet") + {
  document_type: "organisation",
  edition_links: {},
  definitions: {  
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        abbreviation: {
          type: [
            "string",
            "null",
          ],
          description: "The organisation's abbreviation, if it has one.",
        },      
        organisation_type: {
          type: "string",
          enum: [
            "department",
          ],
          description: "The type of organisation.",
        },     
        status: {
          type: "string",
          enum: [
            "closed",
            "live",
          ],
        },           
      }
    }, 
  },     
}