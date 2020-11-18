require 'rexy_admin/filter_params'

module RexyAdmin
  module Action
    def rexy_admin_create(params = {})
      action = :create
      raise "Action #{action} is not set in model #{model_name} yet." unless action.in? @actions

      params = params.permit!.to_h
      execute_action(params, action)
    end

    def default_create(params)
      # params = RexyAdmin::FilterParams.call(self, params).result
      params = RexyAdmin::FilterParams.call(
        model: self,
        params: params,
        destroy_untracking_records: true
      ).result

      create_multiple_records = params[:objects].present?

      if create_multiple_records
        create!(params[:objects])
        { status: 'OK', result: { status: 'OK' } }
      else
        record = create!(params)
        { status: 'OK', result: { id: record.id } }
      end
    end
  end
end
