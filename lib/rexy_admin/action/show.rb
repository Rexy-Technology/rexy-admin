module RexyAdmin
  module Action
    def rexy_admin_show(id, params = {})
      raise "Action show is not set in model #{model_name} yet." unless :show.in? @actions

      params.merge!(id: id)
      cmd = show_cmd(params)
      return {status: 'FAIL', result: cmd.errors} if cmd.failure?
      
      record = cmd.result[:record]
      record = @show_after_action.call(record, params if @show_after_action.present?
      {status: 'OK', result: {
        record: record
      }}
    end

    def show_cmd(params)
      RexyAdmin::Serializer::Serializer.call(
        schema: @show_schema,
        context: @show_context,
        params_checker: @show_params_checker,
        after_query: @show_after_query.presence || default_show_after_query,
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

  end
end