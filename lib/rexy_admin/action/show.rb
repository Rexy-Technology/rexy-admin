# record = Show.call(params.merge(
#   show_customer_query: @show_customer_query,
#   show_associations: @show_associations,
#   show_exclude_fields: @show_exclude_fields,
#   show_fields: @show_fields,
#   show_after_action: @show_after_action)).result
module RexyAdmin
  module Action
    def rexy_admin_show(id, params = {})
      raise "This action is not set in model #{model_name} yet." unless :show.in? @actions
      params.merge!(id: id)
      return custom_show(params) if @show_params_checker.present?

      default_show(params)
    end

    def custom_show params 
      custom_action(params, @show_params_checker, @show_context, @show_command, 'default_show')
    end

    def default_show(params)
      record = @show_custom_query.joins(show_join_array).select(show_select_string).find_by_id(params[:id])
      show_check_if_associations_valid
      record = add_associations_fields_to_record(record) if record.present?
      
      record  = @show_after_action.call(record, params[:current_admin]) if record.present? && @show_after_action.present? 
      return {status: 'OK', result: record}
      
      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

    def show_check_if_associations_valid
      @show_associations.each_with_index do |association, index|
        raise "Associations must be a array of hashes." unless association.is_a?(Hash)
        raise "Field model is required." unless association.key?(:model)
        raise "Association model must be a belongs_to or has_one." unless association[:model].model_name.singular.to_sym.in? belongs_to_or_has_one_relate_model_names
        @show_associations[index][:fields] = association[:fields].presence || []
        (association[:fields].presence || []).each { |association_field| raise("Association fields not exists.") unless association_field.to_s.in? association[:model].column_names }
      end
    end

    def add_associations_fields_to_record record
      to_h_record = record.attributes.transform_keys(&:to_sym)
      @show_associations.each do |association|
        model_object = {}
        association[:fields].each do |association_field|
          foreign_field = "#{association[:model].model_name.singular}__#{association_field}"
          model_object[association_field] = record.send foreign_field
          to_h_record.delete(foreign_field.to_sym)
        end
        to_h_record[association[:model].model_name.singular.to_sym] = model_object
      end
      to_h_record
    end

    # Joins
    def show_join_array
     @show_associations.map { |association_field| association_field[:model].model_name.singular.to_sym }
    end

    def belongs_to_or_has_one_relate_model_names
      belongs_to_names = reflect_on_all_associations(:belongs_to).map(&:name)
      has_one_names = reflect_on_all_associations(:has_one).map(&:name)
      (belongs_to_names + has_one_names).uniq
    end

    # Select
    def show_select_string
      show_primary_keys_string + show_association_keys_string
    end

    def show_primary_keys_string
      primary_keys_string = @show_fields.map do |v|
        "#{table_name}.#{v}" unless EXCLUDE_KEYS_STRING.find_index(v)
      end
      primary_keys_string.compact.join(', ')
    end

    def show_association_keys_string
      return '' unless @show_associations.present?
      association_keys_string = @show_associations.map do |association|
                                    association[:fields].present? ? association[:fields].map do |association_field|
                                                                      unless EXCLUDE_KEYS_STRING.find_index(association_field)
                                                                        "#{association[:model].table_name}.#{association_field} as #{association[:model].model_name.singular}__#{association_field}" 
                                                                      end
                                                                    end
                                                                  :  nil
                                  end
      association_keys_string = association_keys_string&.compact&.join(', ')

      association_keys_string.present? ? ',  ' + association_keys_string : ''
    end

  end
end