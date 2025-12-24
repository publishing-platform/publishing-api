local FileAttachmentAssetProperties = {
  accessible: { type: "boolean", },
  alternative_format_contact_email: { type: "string", },
  attachment_type: { type: "string", enum: ["file"], },
  content_type: { type: "string", },
  file_size: { type: "integer", },
  filename: { type: "string", },
  id: { type: "string" },
  number_of_pages: { type: "integer", },
  title: { type: "string", },
  url: { type: "string", format: "uri", },
};

local HtmlAttachmentAssetProperties = {
  attachment_type: { type: "string", enum: ["html"], },
  id: { type: "string" },
  title: { type: "string", },
  url: { type: "string", format: "uri", },
};

local ExternalAttachmentAssetProperties = {
  attachment_type: { type: "string", enum: ["external"], },
  id: { type: "string" },
  title: { type: "string", },
  url: { type: "string", format: "uri", },
};

local PublicationAttachmentAssetProperties = {
  isbn: { type: "string", },
  unique_reference: { type: "string", },
};

{
  image_asset: {
    type: "object",
    additionalProperties: false,
    required: [
      "url",
    ],
    properties: {
      url: {
        description: "URL to the image. The image should be in a suitable resolution for display on the page.",
        type: "string",
        format: "uri",
      },
      medium_resolution_url: {
        description: "URL to a medium resolution version of the image, for use by devices that have high pixel density such as iphone.",
        type: "string",
        format: "uri",
      },
      high_resolution_url: {
        description: "URL to a high resolution version of the image, for use by third parties such as Twitter, Facebook or Slack. Used by the machine readable metadata component. Don't use this on user-facing web pages, as it might be very large.",
        type: "string",
        format: "uri",
      },
      alt_text: {
        type: "string",
      },
      caption: {
        anyOf: [
          {
            type: "string",
          },
          {
            type: "null",
          },
        ],
      },
      credit: {
        anyOf: [
          {
            type: "string",
          },
          {
            type: "null",
          },
        ],
      },
    },
  },    

  file_attachment_asset: {
    type: "object",
    additionalProperties: false,
    required: [
      "attachment_type",
      "content_type",
      "id",
      "url",
    ],
    properties: FileAttachmentAssetProperties,
  },

  publication_attachment_asset: {
    oneOf: [
      {
        type: "object",
        additionalProperties: false,
        required: [
          "attachment_type",
          "content_type",
          "id",
          "url",
        ],
        properties: FileAttachmentAssetProperties + PublicationAttachmentAssetProperties,
      },
      {
        type: "object",
        additionalProperties: false,
        required: [
          "attachment_type",
          "id",
          "url",
        ],
        properties: HtmlAttachmentAssetProperties + PublicationAttachmentAssetProperties,
      },
      {
        type: "object",
        additionalProperties: false,
        required: [
          "attachment_type",
          "id",
          "url",
        ],
        properties: ExternalAttachmentAssetProperties + PublicationAttachmentAssetProperties,
      }
    ],
  },
}