module RexyAdmin
  module Action
    # Update 
    def rexy_admin_update(id, params = {})
      raise "This action is not set in model #{model_name} yet." unless :update.in? @actions
      params.merge!(id: id)
      return custom_update(params) if @update_params_checker.present?

      default_update(params)
    end
    
    def default_update params
      params = filter_params params
      record = @update_custom_query.find_by_id(params[:id])
      return {status: 'OK', result: {id: params[:id]}} if record.present? && record.update(params)
      
      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

    def custom_update params 
       custom_action(params, @update_params_checker, @update_context, @update_command, 'default_update')
    end

  end
end
