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
    # Show
    def rexy_admin_show(id, params = {})
      raise "This action is not set in model #{model_name} yet." unless :show.in? @actions
      params.merge!(id: id)
      return check_params_and_show(params) if @show_params_checker.present?

      default_show(params)
    end

    def default_show(params)
      record = @show_custom_query.select(@show_fields).find_by_id(params[:id])
      return {status: 'OK', result: record} if record.present?
      
      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

    def check_params_and_show params 
      check_params_and_execute_command(params, @show_params_checker, @show_context, @show_command, 'default_show')
    end

    # Toggle
    def rexy_admin_toggle(id, params = {})
      raise "This action is not set in model #{model_name} yet." unless :toggle.in? @actions
      params.merge!(id: id)
      return check_params_and_toggle(params) if @toggle_params_checker.present?

      default_toggle(params)
    end

    def default_toggle(params)
      record = @toggle_custom_query.find_by_id(params[:id])
      return {status: 'OK', result: {id: params[:id]}} if record.present? && record.toggle(:active) && record.save
      
      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

    def check_params_and_toggle params 
      check_params_and_execute_command(params, @toggle_params_checker, @toggle_context, @toggle_command, 'default_toggle')
    end

    # Delete
    def rexy_admin_delete(id, params = {})
      raise "This action is not set in model #{model_name} yet." unless :delete.in? @actions
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
      raise "This action is not set in model #{model_name} yet." unless :create.in? @actions
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
      raise "This action is not set in model #{model_name} yet." unless :update.in? @actions
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
      args = args.uniq
      all_actions = %i[create update delete show toggle all]
      total_all_actions = all_actions.count
      raise ("use_actions only accept #{total_all_actions} action #{"type".pluralize(total_all_actions)}: #{all_actions}") unless args.all?{|a| a.in? all_actions}

      args = :all.in?(args) ? all_actions.reject {|e| e == :all} : args
      @actions = args || []

      @actions.each do |action|
        set_action action: action
      end
    end

    def set_action(action:, params_checker: nil, context: {}, command: nil, custom_query: where(''), fields: [])
      raise ("action only accept these action types: #{@actions}") unless action.in? @actions
      instance_variable_set("@#{action}_params_checker", params_checker)
      instance_variable_set("@#{action}_context", context)
      instance_variable_set("@#{action}_command", command)
      instance_variable_set("@#{action}_custom_query", custom_query)
      action == :show && instance_variable_set("@#{action}_fields", fields)
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