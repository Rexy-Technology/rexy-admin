module RexyAdmin
  module Action
    def rexy_admin_show(id, params = {})
      raise "This action is not set in model #{model_name} yet." unless :show.in? @actions
      params.merge!(id: id)
      return custom_show(params) if @show_params_checker.present?

      default_show(params)
    end

    def default_show(params)
      fields = @show_fields.presence || column_names - @show_exclude_fields
      record = @show_custom_query.select(fields).find_by_id(params[:id])
      return {status: 'OK', result: @show_after_action.call(record, params[:current_admin])} if record.present?
      
      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

    def custom_show params 
       custom_action(params, @show_params_checker, @show_context, @show_command, 'default_show')
    end
  end
end