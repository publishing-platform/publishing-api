module RequestSpecHelpers
  # Use in request specs to access the response.
  def parsed_response
    JSON.parse(response.body)
  end

  def base_path
    "/vat-rates"
  end

  def content_item_params
    {
      base_path:,
      description: "VAT rates for goods and services",
      document_type: "answer",
      schema_name: "answer",
      first_published_at: Time.zone.parse("2014-01-02T03:04:05.000Z"),
      public_updated_at: Time.zone.parse("2014-05-14T13:00:06.000Z"),
      publishing_app: "publisher",
      redirects: [],
      rendering_app: "frontend",
      phase: "beta",
      details: {},
      routes: [
        {
          path: base_path,
          type: "exact",
        },
      ],
      update_type: "major",
      title: "VAT rates",
    }
  end
end
