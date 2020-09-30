module RexyAdmin
  module Action
    def rexy_admin_get_form_data params = {}
      raise "form_data is not set in model #{model_name} yet." unless @setted_form_data.present?

      return {status: 'OK', result: @get_form_data_command.call(params).result} if @get_form_data_params_checker.nil?

      params_checker_cmd = @get_form_data_params_checker.call(params: params, context: @get_form_data_context.merge(current_admin: params["current_admin"]))
      return {status: 'FAIL', result: params_checker_cmd.errors} if params_checker_cmd.failure?
      
      {status: 'OK', result: @get_form_data_command.call(params_checker_cmd.result).result} if @get_form_data_command.present?
    end

    def set_form_data(
      params_checker: nil,
      context: {},
      command: nil,
      auth_query: nil
    )
      instance_variable_set("@setted_form_data", true)
      instance_variable_set("@get_form_data_params_checker", params_checker)
      instance_variable_set("@get_form_data_context", context)
      instance_variable_set("@get_form_data_command", command)
      instance_variable_set("@get_form_data_auth_query", auth_query)
    end

  end
end
