{
  summary_organisations: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "href",
        "organisation_type",
        "slug",
        "content_id",
      ],
      properties: {
        title: {
          type: "string",
        },
        href: {
          type: "string",
        },        
        organisation_type: {
          type: "string",
        }, 
        slug: {
          type: "string"
        },  
        status: {
          type: [
            "string",
            "null",
          ],
        },       
        content_id: {
          "$ref": "#/definitions/guid",
        },
        abbreviation: {
          type: [
            "string",
            "null",
          ],
        },                               
      }
    },
    description: "A list of all organisations of a particular type.",    
  }
}