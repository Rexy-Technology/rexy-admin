module RexyAdmin
  module Action
    def rexy_admin_toggle(id, params = {})
      action = :toggle
      raise "Action #{action.to_s} is not set in model #{model_name} yet." unless action.in? @actions
      
      params.merge!(id: id)
      execute_action(params, action)
    end

    def default_toggle(params)
      record = find_by_id(params[:id])
      default_toggle_field = :active
      return {status: 'OK', result: {id: params[:id]}} if record.present? && record.toggle(@toggle_field.presence || default_toggle_field) && record.save
      
      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

  end
end