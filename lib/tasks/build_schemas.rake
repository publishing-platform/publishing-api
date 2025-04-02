desc "regenerate schemas and validate"
task build_schemas: %i[
  regenerate_schemas
  validate_dist_schemas
  validate_links
  format_examples
  validate_examples
]
