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

EXCLUDE_SEARCH_STRING = %w[id created_at updated_at active].freeze

module RexyAdmin
  module Query
    def set_params(params)
      @params = params
    end

    def pagination
      @pagination ||= {
        page: (@params[:page].presence || 1).to_i,
        per_page: (@params[:per_page].presence || 10).to_i
      }
    end

    def arrangement
      @arrangement ||= begin
        order_by_param = @params[:order_by]&.strip&.downcase
        order = @params[:order]&.upcase == 'ASC' ? 'ASC' : 'DESC'
        order_by = column_names.include?(order_by_param) ? order_by_param : 'created_at'
        {
          order: order,
          order_by: order_by,
          keyword: @params[:keyword]
        }
      end
    end

    def rexy_admin_query(params = {})
      set_params params
      # cols = table_columns(@params[:columns]).map { |h| h.slice(:field).values }.flatten
      # records = order(order_string).select(cols)
      records = order(order_string)

      rexy_admin_render_table_json(
        records, 
        pagination.merge( total_count: records.page(pagination[:page]).per(pagination[:per_page]).total_count),
        params
      )
    end

    # def filter_records(records, params, filters = [])
    #   # filter = [{ key: '', value: '' }]
    #   filters.inject(records) do |current_records, filter|
    #     next current_records unless params[filter].present?

    #     model_custom_filter = get_custom_filters.detect { |f| f[:key] == filter }
    #     next current_records unless model_custom_filter[:scope]

    #     current_records.send(model_custom_filter[:scope], params[filter])
    #   end
    # end

    def order_string
      "#{arrangement[:order_by]} #{arrangement[:order]}"
    end

    def search_string
      condition_array = column_names.map do |v|
        unless EXCLUDE_SEARCH_STRING.find_index(v)
          "COALESCE(lower(#{table_name}.#{v}), '') LIKE :keyword"
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
