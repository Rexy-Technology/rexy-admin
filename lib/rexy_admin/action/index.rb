module RexyAdmin
  module Action
    def rexy_admin_index(params = {})
      raise "Action index is not set in model #{model_name} yet." unless :index.in? @actions

      cmd = index_cmd(params)
      return {status: 'FAIL', result: cmd.errors} if cmd.failure?
      
      {status: 'OK', result: cmd.result}
    end

    def index_cmd(params)
      RexyAdmin::Serializer::Serializer.call(
        schema: @index_schema,
        context: @index_context,
        params_checker: @index_params_checker,
        after_query: @index_after_query.presence || default_index_after_query,
        after_action: @index_after_action.presence || default_index_after_action,
        many: true,
        paginate: @index_paginate,
        params: params,
       )
    end

    def default_index_after_query
      lambda do |records, params|
        records
      end
    end

    def default_index_after_action
      lambda do |records, params|
        records
      end
    end

  end
end
