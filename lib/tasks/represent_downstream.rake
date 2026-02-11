namespace :represent_downstream do
  desc "Represent all editions downstream"
  task all: :environment do
    content_ids = Document.presented.pluck(:content_id)
    Rake::Task["represent_downstream:content_id"].invoke(*content_ids)
  end

  desc "
  Represent an individual or multiple documents downstream
  Usage
  rake 'represent_downstream:content_id[57a1253c-68d3-4a93-bb47-b67b9b4f6b9a, f5e1d870-d9e2-4767-9175-eec843f2617f]'
  "
  task content_id: :environment do |_t, args|
    content_ids = args.extras

    content_ids.uniq.each_slice(1000).each do |batch|
      Commands::RepresentDownstream.new.call(batch)
      sleep 5
    end
  end
end
