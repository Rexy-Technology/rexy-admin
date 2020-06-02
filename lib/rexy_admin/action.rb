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
      raise 'Action not exists.' unless :show.in? @actions
      find_by_id(id)
    end

    def rexy_admin_toggle_active(id)
      record = find_by_id(id)
      record.active = !record.active
      return 'OK' if record.save

      'FAIL'
    end

    # Delete
    def rexy_admin_delete(id, params = {})
      raise 'Action not exists.' unless :delete.in? @actions
      # Create body param "ids" if not exist in JSON body
      params[:ids] = [] if params[:ids].nil?
      # Push path variable "id" to ids
      params[:ids] << id
      # Filter uniq
      params[:ids] = params[:ids].uniq
      # If path variable "id" not exist, to_i will return 0
      params[:ids] = params[:ids].reject {|id| id == 0 }

      return check_params_and_delete(params) if @delete_params_checker.present?

      default_delete(params)
    end

    def default_delete params
      records = @delete_custom_query.where(id: params[:ids])
      return {status: 'OK', result: {status: 'OK'}} if params[:ids].count == records.count && records.destroy_all

      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

    def check_params_and_delete params 
      check_params_and_execute_command(params, @delete_params_checker, @delete_context, @delete_command, 'default_delete')
    end

    # Create
    def rexy_admin_create(params = {})
      raise 'Action not exists.' unless :create.in? @actions
      params = filter_params params
      return check_params_and_create(params) if @create_params_checker.present?

      default_create(params)
    end

    def default_create params
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

    def check_params_and_create params 
      check_params_and_execute_command(params, @create_params_checker, @create_context, @create_command, 'default_create')
    end
    
    # Update 
    def rexy_admin_update(id, params = {})
      raise 'Action not exists.' unless :update.in? @actions
      params.merge!(id: id)
      params = filter_params params
      return check_params_and_update(params) if @update_params_checker.present?
      default_update(params)
    end
    
    def default_update params
      record = @update_custom_query.find_by_id(params[:id])
      return {status: 'OK', result: {id: params[:id]}} if record.present? && record.update(params)
      
      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

    def check_params_and_update params 
      check_params_and_execute_command(params, @update_params_checker, @update_context, @update_command, 'default_update')
    end

    # Custom
    def check_params_and_execute_command params, params_checker, context, command , default_action
      params_checker_cmd = params_checker.call(params: params, context: context)
      return {status: 'FAIL', result: params_checker_cmd.errors} if params_checker_cmd.failure?
      
      return custom_command(command, params_checker_cmd.result) if command.present?
        
      send default_action, params_checker_cmd.result
    end

    def custom_command command, params
      cmd = command.call(params)
      return {status: 'OK', result: cmd.result} if cmd.success?
    
      {status: 'FAIL', result: cmd.errors}
    end

    # Set action
    def use_actions *args
      raise ('use_actions only accept 4 action types: :create, :update, :delete :show, :all') unless args.all?{|a| a.in? %i[create update delete show all]}
      args = :all.in?(args) ? %i[create update delete show] : args
      @actions = args || []

      @actions.each do |action|
        set_action action: action
      end
    end

    def set_action(action:, params_checker: nil, context: {}, command: nil, custom_query: where(''))
      raise ("action only accept these action types: #{@actions}") unless action.in? @actions
      instance_variable_set("@#{action}_params_checker", params_checker)
      instance_variable_set("@#{action}_context", context)
      instance_variable_set("@#{action}_command", command)
      instance_variable_set("@#{action}_custom_query", custom_query)
    end

    # Helper
    def filter_params params
      filtered_params = {}
      params.each do |key, value|
        filtered_params[key.to_sym] = value if key.to_s.in?(column_names << "password")
      end
      filtered_params
    end
    
  end
end