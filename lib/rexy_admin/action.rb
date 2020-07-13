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
    # def custom_action params, params_checker, context, command , default_action
    #   return custom_action_with_params_checker(params, params_checker, context, command , default_action) if params_checker.present?
    #   custom_action_without_params_checker(params, command , default_action)
    # end

    # def custom_action_with_params_checker params, params_checker, context, command , default_action
    #   params_checker_cmd = params_checker.call(params: params, context: context.merge(current_admin: params["current_admin"]))
    #   return {status: 'FAIL', result: params_checker_cmd.errors} if params_checker_cmd.failure?
      
    #   return custom_command(command, params_checker_cmd.result) if command.present?
        
    #   send default_action, params_checker_cmd.result
    # end

    # def custom_action_without_params_checker params, command , default_action
    #   return custom_command(command, params) if command.present?
          
    #   send default_action, params
    # end

    # def custom_command command, params
    #   cmd = command.call(params)
    #   {status: 'OK', result: cmd.result}
    # end

    # Set action
    def use_actions only: [], except: []
      raise ("Please choose only one in two options only or except") if only.present? && except.present?
      
      total_all_actions = ACTIONS.count

      actions = except.present? ? (ACTIONS - except) : (only.presence || ACTIONS)
      actions = actions.uniq
      raise ("use_actions only accept #{total_all_actions} action #{"type".pluralize(total_all_actions)}: #{ACTIONS}") unless actions.all?{|a| a.in? ACTIONS}
      
      @actions = actions || ACTIONS
      @actions.each do |action|
        set_action action: action
      end
    end

    def set_action(action:, params_checker: nil, context: {},
                   command: nil, custom_query: where(''), fields: [],
                    search_fields: [], schema: [], exclude_fields: [],
                     modify_query: nil, after_action: nil, paginate: false)
      raise ("action only accept these action types: #{@actions}") unless action.in? ACTIONS
      set_mutation_actions(custom_query, context, params_checker, command)
      set_query_actions(schema, context, params_checker, modify_query, paginate)
    end

    def set_mutation_actions(custom_query, context, params_checker, command)
      instance_variable_set("@#{action}_custom_query", custom_query)
      instance_variable_set("@#{action}_context", context)
      instance_variable_set("@#{action}_params_checker", params_checker)
      instance_variable_set("@#{action}_command", command)
    end

    def set_query_actions(schema, context, 
                          fields, search_fields, exclude_fields,
                          params_checker, modify_query, paginate)

      instance_variable_set("@#{action}_context", context)
      instance_variable_set("@#{action}_params_checker", params_checker)

      fields = (fields&.uniq&.presence || column_names - exclude_fields) - EXCLUDE_KEYS_STRING
      search_fields = search_fields&.uniq&.presence || fields           
      schema = {
        model: self,
        fields: fields,
        search_fields: search_fields,
      }                                    

      action.in?([:show, :index, :form]) && instance_variable_set("@#{action}_schema", schema) && 
                                            instance_variable_set("@#{action}_modify_query", modify_query) && 
                                            instance_variable_set("@#{action}_after_action", after_action) &&
                                            instance_variable_set("@#{action}_paginate", paginate)
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

