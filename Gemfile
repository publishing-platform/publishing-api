source "https://rubygems.org"

gem "rails", "~> 7.2.2"

gem "bootsnap", require: false
gem "jsonnet"
gem "json-schema", require: false
gem "oj"
gem "pg", "~> 1.5"
gem "publishing_platform_api_adapters"
gem "publishing_platform_app_config"
gem "publishing_platform_location"
gem "publishing_platform_markdown"
gem "publishing_platform_schemas"
gem "publishing_platform_sidekiq"
gem "publishing_platform_sso"
gem "puma", ">= 5.0"
gem "sentry-sidekiq"
gem "sidekiq-unique-jobs"
gem "tzinfo-data", platforms: %i[mswin mswin64 mingw x64_mingw jruby]
gem "with_advisory_lock"

group :development, :test do
  gem "debug", platforms: %i[mri mswin mswin64 mingw x64_mingw]
  gem "publishing_platform_rubocop"
end

group :development do
  gem "error_highlight", ">= 0.4.0", platforms: [:ruby]
end
