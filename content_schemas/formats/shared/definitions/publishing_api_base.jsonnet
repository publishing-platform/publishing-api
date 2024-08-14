{
  description: {
    type: "string",
  },
  description_optional: {
    anyOf: [
      {
        "$ref": "#/definitions/description",
      },
      {
        type: "null",
      },
    ],
  },
  details: {
    type: "object",
    additionalProperties: false,
    properties: {},
  },
  update_type: {
    enum: [
      "major",
      "minor",
      "republish",
    ],
  },
  title: {
    type: "string",
  },
  title_optional: {
    type: "string",
  },
  multiple_content_types: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "content_type",
        "content",
      ],
      properties: {
        content_type: {
          type: "string",
        },
        content: {
          type: "string",
        },
      },
    },
  },
  change_note: {
    description: "Change note for the most recent update",
    type: [
      "string",
      "null",
    ],
  },
  change_history: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      properties: {
        public_timestamp: {
          type: "string",
          format: "date-time",
        },
        note: {
          type: "string",
          description: "A summary of the change",
        },
      },
      required: [
        "public_timestamp",
        "note",
      ],
    },
  },
  withdrawn_notice: {
    type: "object",
    additionalProperties: false,
    properties: {
      explanation: {
        type: "string",
      },
      withdrawn_at: {
        format: "date-time",
      },
    },
  },
  body: {
    description: "The main content provided as HTML rendered from markdown",
    type: "string",
  },
  body_html_and_markdown: {
    description: "The main content provided as HTML with the markdown markdown it's rendered from",
    anyOf: [
      {
        "$ref": "#/definitions/multiple_content_types",
      },
    ],
  },
  first_published_at: {
    description: "The date the content was first published.  Automatically determined by the publishing-api, unless overridden by the publishing application.",
    type: "string",
    format: "date-time",
  },
  public_updated_at: {
    description: "When the content was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application.",
    type: "string",
    format: "date-time",
  },
  publishing_request_id: {
    description: "A unique identifier used to track publishing requests to rendered content",
    oneOf: [
      { type: "string" },
      { type:"null" },
    ],
  },
  payload_version: {
    description: "Counter to indicate when the payload was generated",
    type: "integer",
  },
}