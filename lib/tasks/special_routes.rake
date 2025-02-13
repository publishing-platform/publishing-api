namespace :special_routes do
  desc "Publish special routes (except the homepage)"
  task publish: :environment do
    SpecialRoutePublisher.publish_special_routes
  end

  desc "Publish the homepage"
  task publish_homepage: :environment do
    SpecialRoutePublisher.publish_homepage
  end
end
