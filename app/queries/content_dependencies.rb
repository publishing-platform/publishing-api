module Queries
  # This class resolves the dependencies for a given content_id
  #
  # There are 2 types of dependency this resolves:
  # 1 - Documents that are linked to the subject of dependency resolution
  #     (eg for a subject of a if b has a link to a b will be returned),
  #     for certain link types these are recursed forming a tree structure.
  # 2 - Documents which have an automatic reverse link to the subject.
  #     These are items this subject links to and is represented reciprocally
  #     in the item linked to. eg if our subject (A) has a parent of B, B would
  #     automatically have a link to A of type children.
  class ContentDependencies
    def initialize(content_id:, content_stores:)
      @content_id = content_id
      @content_stores = content_stores
    end

    def with_drafts?
      content_stores.include?("draft")
    end

    def call
      dependency_resolution.dependencies
    end

  private

    attr_reader :content_id, :content_stores

    def dependency_resolution
      @dependency_resolution ||= DependencyResolution.new(
        content_id,
        with_drafts: with_drafts?,
      )
    end
  end
end
