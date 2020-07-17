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
  module Query
    def rexy_admin_query(params = {})
      raise "Action index is not set in model #{model_name} yet." unless :index.in? @actions

      cmd = index_cmd(params)
      return {status: 'FAIL', result: cmd.errors} if cmd.failure?
      
      records = cmd.result[:records]
      pagination = cmd.result[:pagination]
      records = @index_after_action.call(records, params[:current_admin]) if @index_after_action.present?
      {status: 'OK', result: {
        records: records,
        pagination: pagination
      }}
    end

    def index_cmd(params)
      RexyAdmin::Serializer::Serializer.call(
        schema: @index_schema,
        context: @index_context,
        params_checker: @index_params_checker,
        after_query: @index_after_query.presence || default_index_after_query,
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

  end
end
