module RequestSpecHelpers
  # Use in request specs to access the response.
  def parsed_response
    JSON.parse(response.body)
  end
end
