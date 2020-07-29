module RexyAdmin
  module Query
    def add_queries(queries)
      queries.each { |query| add_query(query)}
    end

    def add_query(
        route: '',
        schema: [],
        associations: [],
        context: {},
        params_checker: nil,
        fields: [],
        search_fields: [],
        exclude_fields: [],
        after_query: nil,
        after_action: nil,
        paginate: true
    )
        fields = (fields&.uniq&.presence || column_names.map(&:to_sym) - exclude_fields) - EXCLUDE_KEYS_STRING
        search_fields = search_fields&.uniq&.presence || fields           

        schema = {
          model: self,
          fields: fields,
          search_fields: search_fields,
          associations: associations,
          has_many: false,
          in_has_many_branch: false
        }      
        raise "This query route already exist, please choose another route." if route_exists?(route)
        
        @queries << {
          route: route,
          context: context,
          params_checker: params_checker,
          schema: schema,
          after_query: after_query,
          after_action: after_action,
          paginate: paginate
        }
    end

    def rexy_admin_query(params = {})
      route = route(params)
      raise "This query route not exist." unless route_exists?(route)

      query = query(route)
      cmd = query_cmd(params, query)
      return {status: 'FAIL', result: cmd.errors} if cmd.failure?
      
      records = cmd.result[:records]
      pagination = cmd.result[:pagination]
      records = query[:after_action].call(records, params) if query[:after_action].present?
      {status: 'OK', result: {
        records: records,
        pagination: pagination
      }}
    end

    def query_cmd(params, query)
      RexyAdmin::Serializer::Serializer.call(
        schema: query[:schema],
        context: query[:context],
        params_checker: query[:params_checker],
        after_query: query[:after_query].presence || default_query_after_query,
        many: true,
        paginate: query[:paginate],
        params: params,
       )
    end

    def default_query_after_query
      lambda do |records, params|
        records
      end
    end

    def route_exists?(route)
      @queries.find_index { |query| query[:route] == route}.present?
    end

    def route(params)
      params[:path_request].split('/').last
    end

    def query(route)
      index = @queries.find_index { |query| query[:route] == route}
      @queries[index]
    end

    def init_queries
      @queries = []
    end
    
  end
end

