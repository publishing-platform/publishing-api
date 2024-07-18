source "https://rubygems.org"

ruby "3.1.2"

gem "rails", "~> 7.1.3", ">= 7.1.3.3"

gem "bootsnap", require: false
gem "jsonnet"
gem "json-schema", require: false
gem "oj"
gem "pg", "~> 1.1"
gem "publishing_platform_api_adapters"
gem "publishing_platform_app_config"
gem "publishing_platform_location"
gem "publishing_platform_schemas"
gem "publishing_platform_sidekiq"
gem "publishing_platform_sso"
gem "puma", ">= 5.0"
gem "sentry-sidekiq"
gem "sidekiq-unique-jobs"
gem "tzinfo-data", platforms: %i[mswin mswin64 mingw x64_mingw jruby]

group :development, :test do
  gem "debug", platforms: %i[mri mswin mswin64 mingw x64_mingw]
  gem "publishing_platform_rubocop"
end

group :development do
  gem "error_highlight", ">= 0.4.0", platforms: [:ruby]
end
