class SpecialRoutePublisher
  def self.publish_special_routes
    new.publish_routes(load_special_routes)
  end

  def self.publish_homepage
    new.publish_routes(load_homepage)
  end

  def self.load_special_routes
    load_all_special_routes.reject { |r| r.fetch(:document_type, nil) == "homepage" }
  end

  def self.load_homepage
    load_all_special_routes.select { |r| r.fetch(:document_type, nil) == "homepage" }
  end

  def self.load_all_special_routes
    YAML.load_file(Rails.root.join("lib/data/special_routes.yaml"))
  end

  def publish_routes(routes)
    routes.each { |r| publish_route(r) }
  end

  def publish_route(route)
    routes = get_routes(route)

    routes.each { |r| Rails.logger.info("Publishing #{r[:type]} route #{r[:path]}, routing to #{route[:rendering_app]}...") }

    content_id = route.fetch(:content_id)

    Commands::ReservePath.call({
      base_path: route.fetch(:base_path),
      publishing_app: "publishing-api",
    })

    Commands::PutContent.call({
      content_id:,
      base_path: route.fetch(:base_path),
      document_type: route.fetch(:document_type, "special_route"),
      schema_name: route.fetch(:document_type, "special_route"),
      title: route.fetch(:title),
      description: route.fetch(:description, ""),
      details: {},
      routes:,
      publishing_app: "publishing-api",
      rendering_app: route[:rendering_app],
      public_updated_at: Time.zone.now.iso8601,
      update_type: route.fetch(:update_type, "major"),
    })

    if route[:links]
      Commands::PatchLinkSet.call({ content_id:, links: route[:links] })
    end

    Commands::Publish.call({ content_id: })
  end

  def get_routes(route)
    routes = [
      {
        path: route.fetch(:base_path),
        type: route.fetch(:type, "exact"),
      },
    ]

    routes + route.fetch(:additional_routes, []).map { |ar| { path: ar[:base_path], type: ar.fetch(:type, "exact") } }
  end
end
