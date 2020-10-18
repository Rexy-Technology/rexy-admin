module RexyAdmin
  module Action
    def rexy_admin_show(id, params = {})
      raise "Action show is not set in model #{model_name} yet." unless :show.in? @actions
      p 'show11'
      params.merge!(id: id)
      cmd = show_cmd(params)
      return { status: 'FAIL', result: cmd.errors } if cmd.failure?
      
      { status: 'OK', result: cmd.result }
    end

    def show_cmd(params)
      RexyAdmin::Serializer::Serializer.call(
        schema: @show_schema,
        context: @show_context,
        params_checker: @show_params_checker,
        after_query: @show_after_query.presence || default_show_after_query,
        after_action: @show_after_action.presence || default_show_after_action,
        many: false,
        paginate: false,
        params: params,
       )
    end

    def default_show_after_query
      lambda do |record, params|
        record.where(id: params[:id])
      end
    end

    def default_show_after_action
      lambda do |record, params|
        record
      end
    end

  end
end