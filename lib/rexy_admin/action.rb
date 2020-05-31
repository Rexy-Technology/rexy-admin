# frozen_string_literal: true

# rubocop:disable AbcSize
# rubocop:disable MethodLength
# rubocop:disable PerceivedComplexity
# rubocop:disable CyclomaticComplexity
# rubocop:disable ModuleLength
# rubocop:disable HandleExceptions, BlockLength
# rubocop:disable EvalWithLocation, Eval
# rubocop:disable ParameterLists
# rubocop:disable Style/Next
# rubocop:disable BlockNesting

module RexyAdmin
  module Action
    def rexy_admin_show(id)
      find_by_id(id)
    end

    def rexy_admin_toggle_active(id)
      record = find_by_id(id)
      record.active = !record.active
      return 'OK' if record.save

      'FAIL'
    end

    def rexy_admin_delete(id)
      record = find_by_id(id)
      return 'OK' if record&.destroy

      'FAIL'
    end

    # Create
    def rexy_admin_create(params = {})
      return check_params_and_create(params) if create_params_checker.present?

      default_create(params)
    end

    def default_create params
      new_record = new(params)
      return {status: 'OK', result: {id: new_record.id}} if new_record.save

      {status: 'FAIL', result: new_record.errors}
    end

    def check_params_and_create params 
      check_params_and_execute_action(params, create_params_checker, create_context, create_action, 'default_create')
    end
    
    # Update 
    def rexy_admin_update(id, params = {})
      params.merge!(id: id)
      return check_params_and_update(params) if update_params_checker.present?

      default_update(params)
    end

    def default_update params
      record = find_by_id(params[:id])
      # return {status: 'FAIL', result: "#{model_name.human} not exist."} if !record.present?

      record.update_attributes(params)
      {status: 'OK', result: {id: params[:id]}}
    end

    def check_params_and_update params 
      check_params_and_execute_action(params, update_params_checker, update_context, update_action, 'default_update')
    end

    # Custom
    def check_params_and_execute_action params, params_checker, context, action , default_action
      params_checker_cmd = params_checker.call(params: params, context: context)
      return {status: 'FAIL', result: params_checker_cmd.errors} if params_checker_cmd.failure?
      
      return custom_action(action, params_checker_cmd.result) if action.present?
        
      send default_action, params_checker_cmd.result
    end

    def custom_action action, params
      cmd = action.call(params)
      return {status: 'OK', result: cmd.result} if cmd.success?
    
      {status: 'FAIL', result: cmd.errors}
    end
    # Set Create
    def set_create_params_checker(create_params_checker, context)
      @create_params_checker = create_params_checker
      @create_context = context
    end

    def set_create_action(create_action)
      @create_action = create_action
    end
    # Set Update 
    def set_update_params_checker(update_params_checker, context)
      @update_params_checker = update_params_checker
      @update_context = context
    end
    
    def set_update_action(update_action)
      @update_action = update_action
    end
    # Create params
    def create_params_checker create_params_checker = nil
      @create_params_checker ||= create_params_checker
    end

    def create_context create_context = {}
      @create_context ||= create_context
    end

    def create_action create_action = nil
      @create_action ||= create_action
    end
    # Update params
    def update_params_checker update_params_checker = nil
      @update_params_checker ||= update_params_checker
    end

    def update_context update_context = {}
      @update_context ||= update_context
    end
    
    def update_action update_action = nil
      @update_action ||= update_action
    end
  end
end
