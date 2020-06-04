module RexyAdmin
  module Action
    def rexy_admin_toggle(id, params = {})
      p '@actions: ' , @actions
      raise "This action is not set in model #{model_name} yet." unless :toggle.in? @actions
      params.merge!(id: id)
      return custom_toggle(params) if @toggle_params_checker.present?

      default_toggle(params)
    end

    def default_toggle(params)
      record = @toggle_custom_query.find_by_id(params[:id])
      return {status: 'OK', result: {id: params[:id]}} if record.present? && record.toggle(:active) && record.save
      
      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

    def custom_toggle params 
       custom_action(params, @toggle_params_checker, @toggle_context, @toggle_command, 'default_toggle')
    end
  end
end