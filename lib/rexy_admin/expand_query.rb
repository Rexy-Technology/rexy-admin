module RexyAdmin
  module ExpandQuery
    def add_expand_queries(expand_queries)
      expand_queries.each do |expand_query|
        add_expand_query(expand_query)
      end
    end

    def add_expand_query(
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
      paginate: true)
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
        raise "This expand query route already exist, please choose another route." if route_exists?(route)
        @expand_queries << {
          route: route,
          context: context,
          params_checker: params_checker,
          schema: schema,
          after_query: after_query,
          after_action: after_action,
          paginate: paginate
        }
    end

    def rexy_admin_expand_query(params = {})
      route = route(params)
      raise "This expand query route not exist." unless route_exists?(route)

      expand_query = expand_query(route)
      cmd = expand_query_cmd(params, expand_query)
      return {status: 'FAIL', result: cmd.errors} if cmd.failure?
      
      records = cmd.result[:records]
      pagination = cmd.result[:pagination]
      records = expand_query[:after_action].call(records, params[:current_admin]) if expand_query[:after_action].present?
      {status: 'OK', result: {
        records: records,
        pagination: pagination
      }}
    end

    def expand_query_cmd(params, expand_query)
      RexyAdmin::Serializer::Serializer.call(
        schema: expand_query[:schema],
        context: expand_query[:context],
        params_checker: expand_query[:params_checker],
        after_query: expand_query[:after_query].presence || default_index_after_query,
        many: true,
        paginate: expand_query[:paginate],
        params: params,
       )
    end

    def default_index_after_query
      lambda do |records, params|
        records
      end
    end

    def route_exists?(route)
      @expand_queries.find_index { |expand_query| expand_query[:route] == route}.present?
    end

    def route(params)
      params[:path_request].split('/').last
    end

    def expand_query(route)
      index = @expand_queries.find_index { |expand_query| expand_query[:route] == route}
      @expand_queries[index]
    end

    def init_expand_queries
      @expand_queries = []
    end
  end
end

