module RexyAdmin
  module Action
    def rexy_admin_create(params = {})
      raise "This action is not set in model #{model_name} yet." unless :create.in? @actions
      return custom_create(params) if @create_params_checker.present?

      default_create(params)
    end

    def default_create params
      params = filter_params params
      result = ''
      create_multiple_records = params[:objects].present?

      if create_multiple_records
        records = create!(params[:objects])
        result = {status: 'OK'}
      else
        record = create!(params)
        result = {id: record.id}
      end
      
      {status: 'OK', result: result}
    end

    def custom_create params 
       custom_action(params, @create_params_checker, @create_context, @create_command, 'default_create')
    end
  end
end
