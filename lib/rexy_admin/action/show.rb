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
      return {status: 'FAIL', result: "#{model_name.human} not exist."} unless record.present?
      @show_associations = check_if_associations_valid self, @show_associations
      record = show_add_associations_fields_to_records(@show_associations, record)
      
      record  = @show_after_action.call(record, params[:current_admin]) if record.present? && @show_after_action.present? 
      {status: 'OK', result: record}
    end

    # Add associations fields
    def show_add_associations_fields_to_records associations, record
      hash_record = record.attributes.transform_keys(&:to_sym)
      add_associations_fields_to_record_recursively('', hash_record, associations)
    end

    # Joins
    def show_join_array
      to_join_array self, @show_associations
    end

    # Select
    def show_select_string
      primary_keys_string(@show_fields) + association_keys_string(@show_associations)
    end
  end
end