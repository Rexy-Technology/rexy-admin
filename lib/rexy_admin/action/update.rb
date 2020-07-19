module RexyAdmin
  module Action
    # Update 
    def rexy_admin_update(id, params = {})
      action = :update
      raise "Action #{action.to_s} is not set in model #{model_name} yet." unless action.in? @actions
      
      params.merge!(id: id)
      execute_action(params, action)
    end
    
    def default_update params
      params = filter_params(params)
      record = find_by_id(params[:id])
      return {status: 'OK', result: {id: params[:id]}} if record.present? && record.update(params)
      
      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

  end
end
