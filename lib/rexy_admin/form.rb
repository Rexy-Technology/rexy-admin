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
  module Form

    def rexy_admin_form(params = {})
      set_params params

      return @form_command.present? ? form_records_filtered_by_custom_command : form_records_filtered_by_default
    end

    def form_records_filtered_by_custom_command
      if @form_params_checker.present?
        params_checker_cmd = @form_params_checker.call(params: @params, context: @form_context.merge(current_admin: @params[:current_admin]))
        return {status: 'FAIL', result: params_checker_cmd.errors} if params_checker_cmd.failure?
        @params = params_checker_cmd.result
      end 
      records = @form_command.call(@params.merge(arrangement: arrangement)).result.page(pagination[:page]).per(pagination[:per_page])
      result_if_success records, pagination.merge(total_count: records.total_count)
    end

    def form_records_filtered_by_default
      records = select(form_select_string)
      records, total_count = form_paginate_and_arrange_records(records)
      records = @form_after_action.call(records, @params[:current_admin], @params) if @form_after_action.present?
      result_if_success records, pagination.merge(total_count: total_count)
    end

    # Select
    def form_select_string
      primary_keys_string(@form_fields)
    end

    def form_paginate_and_arrange_records records
      records = records.where(form_search_string).page(pagination[:page]).per(pagination[:per_page])
      [records, records.total_count]
    end

    # Search
    def form_search_string
      search_string = @form_search_fields.map do |v|
                        unless v.in? EXCLUDE_SEARCH_STRING
                          "COALESCE(lower(#{table_name}.#{v}), '') LIKE '%#{arrangement[:keyword]}%'"
                        end
                      end
      search_string.compact.join(' OR ')
    end

  end
end
