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

require 'rexy_admin/action/create'
require 'rexy_admin/action/update'
require 'rexy_admin/action/show'
require 'rexy_admin/action/toggle'
require 'rexy_admin/action/delete'
# require 'rexy_admin/action/index'
require 'rexy_admin/action/get_form_data'

module RexyAdmin
  module Action
    # Custom
    def custom_action params, params_checker, context, command , default_action
      p 'custom_action'
      return custom_action_with_params_checker(params, params_checker, context, command , default_action) if params_checker.present?
      custom_action_without_params_checker(params, command , default_action)
    end

    def custom_action_with_params_checker params, params_checker, context, command , default_action
      params_checker_cmd = params_checker.call(params: params, context: context.merge(current_admin: params["current_admin"]))
      return {status: 'FAIL', result: params_checker_cmd.errors} if params_checker_cmd.failure?
      
      result = params_checker_cmd.result.merge(current_admin: params["current_admin"])

      return custom_command(command, result) if command.present?
        
      send default_action, result
    end

    def custom_action_without_params_checker params, command , default_action
      return custom_command(command, params) if command.present?
          
      send(default_action, params)
    end

    def custom_command command, params
      cmd = command.call(params)
      {status: 'OK', result: cmd.result}
    end

    # Set action
    def use_actions only: [], except: []
      raise ("Please choose only one in two options only or except") if only.present? && except.present?
      
      total_all_actions = ACTIONS.count

      actions = except.present? ? (ACTIONS - except) : (only.presence || ACTIONS)
      actions = actions.uniq
      raise ("use_actions only accept #{total_all_actions} action #{"type".pluralize(total_all_actions)}: #{ACTIONS}") unless actions.all?{|a| a.in? ACTIONS}
      
      @actions = actions || ACTIONS
      p '@actions: ' , @actions
      @actions.each do |action|
        set_action action: action
      end
    end

    def set_action(
      action:,
      params_checker: nil,
      context: {},
      command: nil,
      custom_query: where(''),
      fields: [],
      search_fields: [],
      associations: [],
      exclude_fields: [],
      after_query: nil,
      after_action: nil,
      auth_query: nil
    )
      raise ("action only accept these action types: #{@actions}") unless action.in? ACTIONS

      instance_variable_set("@#{action}_custom_query", custom_query)
      instance_variable_set("@#{action}_context", context)
      instance_variable_set("@#{action}_command", command)
      instance_variable_set("@#{action}_params_checker", params_checker)
      instance_variable_set("@#{action}_auth_query", auth_query)

      action.in?([:index, :form]) && instance_variable_set("@#{action}_after_query", after_query)
      
      fields = (fields&.uniq&.presence || column_names - exclude_fields) - EXCLUDE_KEYS_STRING
      action.in?([:show, :index, :form]) && instance_variable_set("@#{action}_associations", associations) && 
                                              instance_variable_set("@#{action}_exclude_fields", exclude_fields) &&
                                              instance_variable_set("@#{action}_fields", fields) && 
                                              instance_variable_set("@#{action}_after_action", after_action)

      search_fields = search_fields&.uniq&.presence || fields                                               

      action.in?([:form, :index]) && instance_variable_set("@#{action}_search_fields", search_fields)
    end

    def filter_params params
      filtered_params = {}
      params.each do |key, value|
        filtered_params[key.to_sym] = value if key.to_s.in?(column_names + ["password"])
      end
      filtered_params
    end
    
  end
end

