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

      records = @index_custom_query
      records = records.where(search_string).order(order_string).page(pagination[:page]).per(pagination[:per_page])
      records = @index_command.present? ? @index_command.call(records).result : @index_after_action.call(records)

      rexy_admin_render_table_json(
        records, 
        pagination.merge( total_count: records.count)
      )
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

    def set_index(command: nil, custom_query: where(''), after_action: nil)
      instance_variable_set("@index_command", command)
      instance_variable_set("@index_custom_query", custom_query)
      instance_variable_set("@index_after_action", after_action)
    end
  end
end
