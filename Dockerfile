ARG ruby_version=3.4
ARG base_image=ghcr.io/publishing-platform/publishing-platform-ruby-base:$ruby_version
ARG builder_image=ghcr.io/publishing-platform/publishing-platform-ruby-builder:$ruby_version

FROM $builder_image AS builder

WORKDIR $APP_HOME
COPY Gemfile* .ruby-version ./
RUN JSONNET_USE_SYSTEM_LIBRARIES=1 bundle install
COPY . .
RUN bootsnap precompile --gemfile .

FROM $base_image

ENV PUBLISHING_PLATFORM_APP_NAME=publishing-api

WORKDIR $APP_HOME
COPY --from=builder $BUNDLE_PATH $BUNDLE_PATH
COPY --from=builder $BOOTSNAP_CACHE_DIR $BOOTSNAP_CACHE_DIR
COPY --from=builder $APP_HOME .

USER app
CMD ["puma"]