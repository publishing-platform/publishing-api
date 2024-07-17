{
  rendering_app: {
    description: "The application that renders this item.",
    type: "string",
    enum: [
      "frontend",
    ],
  },
  rendering_app_optional: {
    anyOf: [
      {
        "$ref": "#/definitions/rendering_app",
      },
      {
        type: "null",
      },
    ],
  },
}