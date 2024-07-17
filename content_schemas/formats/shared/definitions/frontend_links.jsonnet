{
  frontend_links: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: true,
      required: [
        "content_id",
        "title",
      ],
      properties: {
        document_type: {
          type: "string",
        },
        schema_name: {
          type: "string",
        },
        base_path: {
          "$ref": "#/definitions/absolute_path",
        },
        api_path: {
          "$ref": "#/definitions/absolute_path",
        },
        public_updated_at: {
          oneOf: [
            { "$ref": "#/definitions/public_updated_at" },
            { type: "null" },
          ],
        },
        content_id: {
          "$ref": "#/definitions/guid",
        },
        title: {
          type: "string",
        },
        links: {
          type: "object",
          patternProperties: {
            "^[a-z_]+$": {
              "$ref": "#/definitions/frontend_links",
            }
          }
        },
      },
    },
  },
  frontend_links_with_base_path: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: true,
      required: [
        "base_path",
        "content_id",
        "title",
      ],
      properties: {
        document_type: {
          type: "string",
        },
        schema_name: {
          type: "string",
        },
        base_path: {
          "$ref": "#/definitions/absolute_path",
        },
        api_path: {
          "$ref": "#/definitions/absolute_path",
        },
        public_updated_at: {
          oneOf: [
            { "$ref": "#/definitions/public_updated_at" },
            { type: "null" },
          ],
        },
        content_id: {
          "$ref": "#/definitions/guid",
        },
        title: {
          type: "string",
        },
        links: {
          type: "object",
          patternProperties: {
            "^[a-z_]+$": {
              "$ref": "#/definitions/frontend_links_with_base_path",
            }
          }
        },
      },
    },
  },
}