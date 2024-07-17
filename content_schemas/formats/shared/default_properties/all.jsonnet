{
  details: {
    "$ref": "#/definitions/details",
  },
  phase: {
    description: "The service design phase of this content item",
    type: "string",
    enum: [
      "alpha",
      "beta",
      "live",
    ],
  },
  publishing_app: {
    "$ref": "#/definitions/publishing_app_name",
  },
}