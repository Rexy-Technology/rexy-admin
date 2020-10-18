# frozen_string_literal: true

module RexyAdmin
  module Action
    def rexy_admin_get_form_data(params = {})
      raise "form_data is not set in model #{model_name} yet." unless @setted_form_data.present?
      raise "command for form_data is not set in model #{model_name} yet." unless @get_form_data_command.present?

      # if @get_form_data_params_checker.present?
      #   params_checker_cmd = @get_form_data_params_checker.call(params: params, context: @get_form_data_context.merge(current_admin: params["current_admin"]))
      #   return { status: 'FAIL', result: params_checker_cmd.errors } if params_checker_cmd.failure?

      #   params = params_checker_cmd.result
      # end

      params_checker_cmd = @get_form_data_command.call(params)
      return { status: 'FAIL', result: params_checker_cmd.errors } if params_checker_cmd.failure?

      { status: 'OK', result: params_checker_cmd.result }
    end

    def set_form_data(params_checker: nil, context: {}, command: nil)
      instance_variable_set("@setted_form_data", true)
      instance_variable_set("@get_form_data_command", command)
      # instance_variable_set("@get_form_data_params_checker", params_checker)
      # instance_variable_set("@get_form_data_context", context)
    end
  end
end
