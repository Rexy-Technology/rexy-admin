# frozen_string_literal: true

require 'rexy_admin/action/create'
require 'rexy_admin/action/update'
require 'rexy_admin/action/show'
require 'rexy_admin/action/toggle'
require 'rexy_admin/action/delete'
require 'rexy_admin/action/index'
require 'rexy_admin/action/get_form_data'

module RexyAdmin
  module Action
    # Set action
    def use_actions(only: [], except: [])
      raise ('Please choose only one in two options only or except') if only.present? && except.present?

      total_all_actions = ACTIONS.count

      actions = except.present? ? (ACTIONS - except) : (only.presence || ACTIONS)
      actions = actions.uniq
      raise ("use_actions only accept #{total_all_actions} action #{'type'.pluralize(total_all_actions)}: #{ACTIONS}") unless actions.all?{|a| a.in? ACTIONS}

      @actions = actions || ACTIONS
      @actions.each do |action|
        set_action action: action
      end
    end

    def set_action(**kwargs)
      action = kwargs[:action]

      raise("action only accept these action types: #{@actions}") unless action.in? ACTIONS

      if action.in?(%i[create update delete toggle])
        set_mutation_actions(kwargs)
      else
        set_query_actions(kwargs)
      end
    end

    def set_mutation_actions(action:,
                             context: {},
                             params_checker: nil,
                             command: nil,
                             toggle_field: :active,
                             auth_query: nil
                             )

      instance_variable_set("@#{action}_context", context)
      instance_variable_set("@#{action}_params_checker", params_checker)
      instance_variable_set("@#{action}_command", command)
      instance_variable_set("@#{action}_auth_query", auth_query)

      instance_variable_set('@toggle_field', toggle_field) if action == :toggle && column_names.map(&:to_sym).include?(toggle_field)
    end

    def set_query_actions(action:,
                          associations: [],
                          context: {},
                          params_checker: nil,
                          fields: [],
                          search_fields: [],
                          exclude_fields: [],
                          after_query: nil,
                          after_action: nil,
                          paginate: true,
                          auth_query: nil
                          )
      fields = (fields&.uniq&.presence || column_names.map(&:to_sym) - exclude_fields) - EXCLUDE_KEYS_STRING

      schema = {
        model: self,
        fields: fields,
        search_fields: search_fields,
        associations: associations,
        has_many: false,
        in_has_many_branch: false
      }

      instance_variable_set("@#{action}_context", context)
      instance_variable_set("@#{action}_params_checker", params_checker)
      instance_variable_set("@#{action}_schema", schema)
      instance_variable_set("@#{action}_after_query", after_query)
      instance_variable_set("@#{action}_after_action", after_action)
      instance_variable_set("@#{action}_paginate", paginate)
      instance_variable_set("@#{action}_auth_query", auth_query)
    end

    # Custom
    def execute_action(params, action)
      action, params_checker, context, custom_command, default_action = action_variables(action)

      if params_checker.present?
        params_checker_cmd = params_checker.call(params: params, context: context.merge(current_admin: params["current_admin"]))
        return { status: 'FAIL', result: params_checker_cmd.errors } if params_checker_cmd.failure?

        params = params_checker_cmd.result
      end

      return execute_custom_command(custom_command, params) if custom_command.present?

      execute_default_action(default_action, params)
    end

    def action_variables(action)
      action = action.to_s
      # Dynamically get instance_variables
      # (e.g., create_params_checker, create_context,
      #  create_custom_command, default_create)
      params_checker = instance_variable_get("@#{action}_params_checker")
      context = instance_variable_get("@#{action}_context")
      custom_command = instance_variable_get("@#{action}_command")

      default_action = "default_#{action}"
      [action, params_checker, context, custom_command, default_action]
    end

    def execute_custom_command(command, params)
      cmd = command.call(params)
      return { status: 'FAIL', result: cmd.errors } if cmd.failure?

      { status: 'OK', result: cmd.result }
    end

    def execute_default_action(command, params)
      send(command, params)
    end
  end
end
