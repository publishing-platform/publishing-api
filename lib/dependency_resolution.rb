#
# This is the core class of Dependency Resolution which is a complicated concept
# in the Publishing API
#
class DependencyResolution
  attr_reader :content_id, :with_drafts

  def initialize(content_id, with_drafts: false)
    @content_id = content_id
    @with_drafts = with_drafts
  end

  def dependencies
    link_graph.links_content_ids
  end

  def link_graph
    @link_graph ||= LinkGraph.new(
      root_content_id: content_id,
      with_drafts:,
      link_reference: LinkReference.new,
    )
  end
end
