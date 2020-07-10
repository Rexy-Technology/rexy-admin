module RexyAdmin
  module Query
    
    def index_select_string
      primary_select_fields_string(@index_fields) + association_select_fields_string(@index_associations)
    end

    def primary_select_fields_string fields
      primary_select_fields_string = fields.map do |v|
        "#{table_name}.#{v}" unless EXCLUDE_KEYS_STRING.find_index(v)
      end
      primary_select_fields_string.compact.join(', ')
    end

    def association_select_fields_string associations
      return '' unless associations.present?
      full_association_select_fields_string = to_association_select_fields_string('', associations)
      
      full_association_select_fields_string.present? ? ', ' + full_association_select_fields_string : ''
    end
    
    # If a relation is has_many, not select it's field and it's predecessor => not sort, search them; only show them.
    def to_association_select_fields_string parents_encode_name , associations
      association_select_fields_string = associations.map do |association|
                                  next if association[:in_has_many_branch] || !association[:fields].present?
                                  
                                  model_name = association[:model].model_name.singular
                                  added_parents_encode_name = "#{parents_encode_name}#{model_name}__"
                                  current_select_fields_string = to_current_select_fields_string(association, added_parents_encode_name, parents_encode_name)
                                  next(current_select_fields_string) unless association.key?(:associations)
                                  child_select_fields_string = to_association_select_fields_string(added_parents_encode_name, association[:associations])
                                  current_select_fields_string + (child_select_fields_string.presence || '')
                                end
      association_select_fields_string&.compact&.join
    end
    
    def to_current_select_fields_string association, added_parents_encode_name, parents_encode_name
      current_select_fields_string = association[:fields].map do |association_field|
        unless EXCLUDE_KEYS_STRING.find_index(association_field)
          current_encode_name = "#{added_parents_encode_name}#{association_field}"
          "#{association[:model].table_name}.#{association_field} as #{current_encode_name}" 
        end
      end
      current_select_fields_string = current_select_fields_string&.compact&.join(', ')
      is_outest_hash = parents_encode_name == ''
      current_select_fields_string.present? ? (is_outest_hash ? current_select_fields_string :  ', ' + current_select_fields_string) : ''
    end

  end
end
