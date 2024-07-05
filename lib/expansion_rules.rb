module ExpansionRules
  module_function
  
    module RecurringLinks
      refine Symbol do
        def recurring
          [self]
        end
      end
    end
  
    using RecurringLinks
  
    def details_fields(*fields)
      fields.map { |field| [:details, field] }
    end
  
    MULTI_LEVEL_LINK_PATHS = [
      [:parent.recurring],
    ].freeze
  
    REVERSE_LINKS = {
      parent: :children,
    }.freeze
  
    # These fields are required by the frontend_links definition
    MANDATORY_FIELDS = %i[
      content_id
      title
    ].freeze
  
    DEFAULT_FIELDS = MANDATORY_FIELDS + %i[
      api_path
      base_path
      document_type
      public_updated_at
      schema_name
      withdrawn
    ].freeze
  
    DRAFT_ONLY_FIELDS = %i[auth_bypass_ids].freeze
  
    DEFAULT_FIELDS_AND_DESCRIPTION = (DEFAULT_FIELDS + [:description]).freeze
  
    CUSTOM_EXPANSION_FIELDS = (
      [
        { document_type: :redirect,
          fields: [] },
        { document_type: :gone,
          fields: [] },
      ]
    ).freeze
  
    POSSIBLE_FIELDS_FOR_LINK_EXPANSION = DEFAULT_FIELDS +
      %i[details] +
      %i[id state phase description auth_bypass_ids unpublishings.type] -
      %i[api_path withdrawn]
  
    def reverse_links
      REVERSE_LINKS.values.uniq
    end
  
    def reverse_link_type(link_type)
      REVERSE_LINKS[link_type.to_sym]
    end
  
    def reverse_to_direct_link_type(link_type)
      REVERSE_LINKS
        .filter { |_, value| value == link_type.to_sym }
        .keys
    end
  
    def is_reverse_link_type?(link_type)
      reverse_to_direct_link_type(link_type).present?
    end
  
    def reverse_to_direct_link_types(link_types)
      return unless link_types
  
      link_types.flat_map { |type| reverse_to_direct_link_type(type) }.compact
    end
  
    def reverse_link_types_hash(link_types)
      link_types.each_with_object({}) do |(link_type, content_ids), memo|
        reversed = reverse_link_type(link_type)
        if reversed
          memo[reversed] ||= []
          memo[reversed] += content_ids
        end
      end
    end
  
    def link_expansion
      # TODO
      # @link_expansion ||= ExpansionRules::LinkExpansion.new(self)
    end
  
    def dependency_resolution
      # TODO
      # @dependency_resolution ||= ExpansionRules::DependencyResolution.new(self)
    end
  
    def expansion_fields(document_type, link_type: nil, draft: true)
      fields = if link_type
                 expansion_fields_for_linked_document_type(document_type, link_type)
               else
                 expansion_fields_for_document_type(document_type)
               end
  
      draft ? fields : fields - DRAFT_ONLY_FIELDS
    end
  
    def expansion_fields_for_document_type(document_type)
      matching_document_types = CUSTOM_EXPANSION_FIELDS.select do |item|
        item[:document_type] == document_type.to_sym
      end
  
      return DEFAULT_FIELDS unless matching_document_types.any?
  
      collated_fields = matching_document_types.flat_map { |item| item[:fields] }
      matches_any_link_type = matching_document_types.any? { |item| item[:link_type].nil? }
  
      collated_fields += DEFAULT_FIELDS unless matches_any_link_type
      collated_fields.uniq
    end
  
    def expansion_fields_for_linked_document_type(document_type, link_type)
      matching_link = CUSTOM_EXPANSION_FIELDS.find do |item|
        item[:document_type] == document_type.to_sym &&
          item[:link_type] == link_type.to_sym
      end
      return matching_link[:fields] if matching_link
  
      matching_document_type = CUSTOM_EXPANSION_FIELDS.find do |item|
        item[:document_type] == document_type.to_sym && item[:link_type].nil?
      end
      return matching_document_type[:fields] if matching_document_type
  
      DEFAULT_FIELDS
    end
  
    module HashWithDigSet
      refine Hash do
        def dig_set(keys, value)
          keys.each_with_index.inject(self) do |hash, (key, index)|
            if keys.count - 1 == index
              hash[key] = value
            else
              hash[key] ||= {}
            end
          end
        end
      end
    end
  
    using HashWithDigSet
  
    def expand_fields(edition_hash, link_type: nil, draft: true)
      fields = expansion_fields(
        edition_hash[:document_type],
        link_type:,
        draft:,
      )
  
      fields.each_with_object({}) do |field, expanded|
        field = Array(field)
        # equivelant to: expanded.dig(*field) = edition_hash.dig(*field)
        expanded.dig_set(field, edition_hash.dig(*field))
      end
    end
  
    def next_allowed_direct_link_types(next_allowed_link_types, reverse_to_direct: false)
      next_allowed_link_types.each_with_object({}) do |(link_type, allowed_links), memo|
        next if allowed_links.empty?
  
        links = allowed_links.reject { |link| is_reverse_link_type?(link) }
        next if links.empty?
  
        link_types = if reverse_to_direct && (reverse_link_types = reverse_to_direct_link_type(link_type)).present?
                       reverse_link_types
                     else
                       [link_type]
                     end
  
        link_types.each { |type| memo[type] = links }
      end
    end
  
    def next_allowed_reverse_link_types(next_allowed_link_types, reverse_to_direct: false)
      next_allowed_link_types.each_with_object({}) do |(link_type, allowed_links), memo|
        next if allowed_links.empty?
  
        links = allowed_links.select { |link| is_reverse_link_type?(link) }
        links = reverse_to_direct_link_types(links) if reverse_to_direct
        next if links.empty?
  
        link_types = if reverse_to_direct && (reverse_link_types = reverse_to_direct_link_type(link_type)).present?
                       reverse_link_types
                     else
                       [link_type]
                     end
  
        link_types.each { |type| memo[type] = links }
      end
    end
  end