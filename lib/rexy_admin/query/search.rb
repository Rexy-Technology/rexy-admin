module RexyAdmin
  module Query
    def index_search_fields_search_string
      primary_search_fields_string(@index_fields) + association_search_fields_string(@index_associations)
    end

    def primary_search_fields_string fields
      primary_search_fields_string = fields.map do |v|
        "#{table_name}.#{v}" unless EXCLUDE_KEYS_STRING.find_index(v)
      end
      primary_search_fields_string.compact.join(', ')
    end

    def association_search_fields_string associations
      return '' unless associations.present?
      full_association_search_fields_string = to_association_search_fields_string('', associations)
      
      full_association_search_fields_string.present? ? ', ' + full_association_search_fields_string : ''
    end
    
    def to_association_search_fields_string parents_encode_name , associations
      association_search_fields_string = associations.map do |association|
                                      model_name = association[:model].model_name.singular
                                      added_parents_encode_name = "#{parents_encode_name}#{model_name}__"
                                      current_search_fields_string = to_current_search_fields_string(association, added_parents_encode_name, parents_encode_name)
                                      next(current_search_fields_string) unless association.key?(:associations)

                                      child_search_fields_string = to_association_search_fields_string(added_parents_encode_name, association[:associations])
                                      current_search_fields_string + (child_search_fields_string.presence || '')
                                    end
      association_search_fields_string&.compact&.join
    end

    def index_search_fields_search_array
      index_search_fields_search_string.split(', ').map do |v|
        # Example: remove all " as " to get an associations array
        if ' as '.in? v
          index = v.index ' as '
          next(v[0..index-1])
        end
        v
      end
    end

    def to_current_search_fields_string association, added_parents_encode_name, parents_encode_name
      p 'jeje1: ' , association[:search_fields]
      current_search_fields_string = association[:search_fields].map do |association_field|
        unless EXCLUDE_KEYS_STRING.find_index(association_field)
          current_encode_name = "#{added_parents_encode_name}#{association_field}"
          "#{association[:model].table_name}.#{association_field} as #{current_encode_name}" 
        end
      end
      current_search_fields_string = current_search_fields_string&.compact&.join(', ')
      is_outest_hash = parents_encode_name == ''
      current_search_fields_string.present? ? (is_outest_hash ? current_search_fields_string :  ', ' + current_search_fields_string) : ''
    end

    def search_string
      search_string = index_search_fields_search_array.map do |v|
                        # Example: "materials.id", "materials.supplier_id"
                        unless v.split('.').last == 'id' || v.last(3) == '_id'
                          "COALESCE(lower(#{v}), '') LIKE '%#{arrangement[:keyword]}%'"
                        end
                      end
      search_string.compact.join(' OR ')
    end
  end
end
