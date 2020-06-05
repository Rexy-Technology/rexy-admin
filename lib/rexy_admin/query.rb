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

# EXCLUDE_SEARCH_STRING = %w[id created_at updated_at active password].freeze
EXCLUDE_SEARCH_STRING = %w[id created_at password].freeze

module RexyAdmin
  module Query
    def set_params(params)
      @params = params
    end

    def pagination
      {
        page: (@params[:page].presence || 1).to_i,
        per_page: (@params[:per_page].presence || 10).to_i
      }
    end

    def arrangement
      order_by_param = @params[:order_by]&.strip&.downcase
      order = @params[:order]&.upcase == 'ASCEND' ? 'ASC' : 'DESC'
      order_by = column_names.include?(order_by_param) ? order_by_param : 'created_at'
      {
        order: order,
        order_by: order_by,
        keyword: @params[:keyword]
      }
    end

    def rexy_admin_query(params = {})
      set_params params

      return @index_command.present? ? records_filtered_by_custom_command : records_filtered_by_default
    end

    def records_filtered_by_custom_command
      if @index_params_checker.present?
        params_checker_cmd = @index_params_checker.call(params: @params, context: @index_context.merge(current_admin: @params[:current_admin]))
        return {status: 'FAIL', result: params_checker_cmd.errors} if params_checker_cmd.failure?
        @params = params_checker_cmd.result
      end 
      records = @index_command.call(@params).result
      records = paginate_and_arrange_records records
      result_if_success records
    end

    def records_filtered_by_default
      fields =  (@index_fields.presence || column_names - @index_exclude_fields) - EXCLUDE_KEYS
      records = @index_custom_query.select(fields)
      records = paginate_and_arrange_records records
      records = @index_after_action.call(records, @params[:current_admin]) if @index_after_action.present?
      result_if_success records
    end

    def result_if_success records
      {
        status: 'OK', result: rexy_admin_render_table_json(
          records, 
          pagination.merge( total_count: @total_count)
        )
      }
    end

    def paginate_and_arrange_records records
      records_before_limit = records.where(search_string).order(order_string)
      @total_count = records_before_limit.size
      records_before_limit.page(pagination[:page]).per(pagination[:per_page])
    end

    def order_string
      "#{arrangement[:order_by]} #{arrangement[:order]}"
    end

    def search_string
      condition_array = column_names.map do |v|
        unless EXCLUDE_SEARCH_STRING.find_index(v)
          "COALESCE(lower(#{table_name}.#{v}), '') LIKE '%#{arrangement[:keyword]}%'"
        end
      end
      condition_array.compact.join(' OR ')
    end

    def add_actions(records)
      records.map(&:add_actions)
    end

    def rexy_admin_entity_resource
      rexy_admin_active.to_a.map do |rc|
        {
          label: rc.name,
          value: rc.id
        }
      end
    end

    def rexy_admin_active
      column_names.include?('active') ? where(active: true) : all
    end

  end
end
