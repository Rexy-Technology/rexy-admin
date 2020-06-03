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
      return custom_action_with_params_checker(params, params_checker, context, command , default_action) if params_checker.present?
      custom_action_without_params_checker(params, command , default_action)
    end

    def custom_action_with_params_checker params, params_checker, context, command , default_action
      params_checker_cmd = params_checker.call(params: params, context: context.merge(current_admin: params["current_admin"]))
      return {status: 'FAIL', result: params_checker_cmd.errors} if params_checker_cmd.failure?
      
      return custom_command(command, params_checker_cmd.result) if command.present?
        
      send default_action, params_checker_cmd.result
    end

    def custom_action_without_params_checker params, command , default_action
      return custom_command(command, params) if command.present?
          
      send default_action, params
    end

    def custom_command command, params
      cmd = command.call(params)
      {status: 'OK', result: cmd.result}
      # return {status: 'OK', result: cmd.result} if cmd.success?
    
      # {status: 'FAIL', result: cmd.errors}
    end

    # Set action
    def use_actions only: [], except: []
      raise ("Please choose only one in two options: [only, except]") if only.present? && except.present?
      
      all_actions = %i[create update delete show toggle index all]
      total_all_actions = all_actions.count

      actions = except.present? ? (all_actions - except) : (only.presence || all_actions)
      actions = actions.uniq
      raise ("use_actions only accept #{total_all_actions} action #{"type".pluralize(total_all_actions)}: #{all_actions}") unless actions.all?{|a| a.in? all_actions}
      
      actions = :all.in?(actions) ? all_actions.reject {|e| e == :all} : actions
      @actions = actions || []

      @actions.each do |action|
        set_action action: action
      end
    end

    def set_action(action:, params_checker: nil, context: {}, command: nil, custom_query: where(''), fields: [], exclude_fields: [], after_action: nil)
      raise ("action only accept these action types: #{@actions}") unless action.in? @actions

      instance_variable_set("@#{action}_custom_query", custom_query)
      action.in?([:show, :index]) && instance_variable_set("@#{action}_fields", fields) && 
                                     instance_variable_set("@#{action}_exclude_fields", exclude_fields) && 
                                     instance_variable_set("@#{action}_after_action", after_action)
      !action.in?([:index]) && instance_variable_set("@#{action}_params_checker", params_checker)
      instance_variable_set("@#{action}_context", context)
      instance_variable_set("@#{action}_command", command)
    end

    def filter_params params
      filtered_params = {}
      params.each do |key, value|
        filtered_params[key.to_sym] = value if key.to_s.in?(column_names << "password")
      end
      filtered_params
    end
    
  end
end

