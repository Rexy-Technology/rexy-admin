require 'rexy_admin/filter_params'
module RexyAdmin
  module Action
    # Update
    def rexy_admin_update(id, params = {})
      action = :update
      raise "Action #{action} is not set in model #{model_name} yet." unless action.in? @actions

      params.merge!(id: id)
      params = params.permit!.to_h
      execute_action(params, action)
    end

    def default_update(params)
      # params = RexyAdmin::FilterParams.call(self, params).result
      params = RexyAdmin::FilterParams.call(
        model: self,
        params: params,
        destroy_untracking_records: true
      ).result

      record = find_by_id(params[:id])

      return { status: 'OK', result: { id: params[:id] } } if record.present? && record.update(params)

      { status: 'FAIL', result: "#{model_name.human} not exist." }
    end
  end
end
