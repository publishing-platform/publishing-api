source "https://rubygems.org"

gem "rails", "8.0.2"

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
gem "sentry-sidekiq"
gem "sidekiq-unique-jobs", "< 8.0.12"
gem "tzinfo-data", platforms: %i[mswin mswin64 mingw x64_mingw jruby]
gem "with_advisory_lock"

group :development, :test do
  gem "brakeman"
  gem "debug", platforms: %i[mri mswin mswin64 mingw x64_mingw]
  gem "factory_bot_rails"
  gem "publishing_platform_rubocop"
  gem "rspec-rails"
  gem "timecop"
  gem "webmock", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "simplecov"
end
