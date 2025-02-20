module DependencyResolutionHelper
  def create_link_set(content_id = nil, links_hash: {})
    document = create(:document, content_id: content_id || SecureRandom.uuid)
    link_set = create(
      :link_set,
      document:,
      content_id: document.content_id,
      links_hash:,
    )
    link_set.content_id
  end

  def create_edition(
    content_id,
    base_path,
    factory: :live_edition,
    links_hash: {},
    version: 1,
    **kwargs
  )
    create(
      factory,
      document: Document.find_or_create_by(content_id:),
      base_path:,
      user_facing_version: version,
      links_hash:,
      **kwargs,
    )
  end

  def create_link(from, to, link_type, link_position = 0)
    document = Document.find_or_create_by!(content_id: from)
    link_set = LinkSet.find_or_create_by!(document:)

    create(
      :link,
      link_set:,
      target_content_id: to,
      link_type:,
      position: link_position,
    )
  end
end
