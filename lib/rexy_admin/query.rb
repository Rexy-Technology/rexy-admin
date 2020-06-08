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

EXCLUDE_SEARCH_STRING = %w[id created_at password].freeze
EXCLUDE_KEYS_STRING = %w[password_digest created_at deleted_at].freeze
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
      order_by = @params[:order_by]&.strip&.downcase
      order = @params[:order]&.upcase == 'ASCEND' ? 'ASC' : 'DESC'
      # order_by = column_names.include?(order_by_param) ? order_by_param : 'created_at'
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
      records, total_count = @index_command.call(@params.merge(pagination: pagination, arrangement: arrangement)).result
      result_if_success records, pagination.merge(total_count: total_count)
    end

    def records_filtered_by_default
      # p '@index_foreign_fields: ' , @index_foreign_fields
      # p 'joins: ' , relate_model_names
      # p 'select: ' , full_keys_string
      # p 'search: ' , full_search_string
      records = joins(relate_model_names).select(full_keys_string)
      records, total_count = paginate_and_arrange_records records
      records = @index_after_action.call(records, @params[:current_admin]) if @index_after_action.present?
      result_if_success records, pagination.merge(total_count: total_count)
    end

    def result_if_success records, pagination
      {
        status: 'OK', result: rexy_admin_render_table_json(
          records, 
          pagination
        )
      }
    end

    def paginate_and_arrange_records records
      records_before_limit = records.where(full_search_string).order(order_string)
      [records_before_limit.page(pagination[:page]).per(pagination[:per_page]), records_before_limit.size]
    end

    def belongs_to_or_has_one_relate_model_names
      belongs_to_names = reflect_on_all_associations(:belongs_to).map(&:name)
      has_one_names = reflect_on_all_associations(:has_one).map(&:name)
      (belongs_to_names + has_one_names).uniq
    end

    def relate_model_names
      @index_foreign_fields.map { |foreign_field| foreign_field[0]}\
                           .select { |relation_model_name| relation_model_name.in? belongs_to_or_has_one_relate_model_names}
    end

    def order_string
      "#{order_by_string} #{arrangement[:order]}"
    end

    def order_by_string
      order_by = ''
      @index_fields.each do|v|
        if arrangement[:order_by] == v.to_s
          order_by = "#{table_name}.#{arrangement[:order_by]}" 
          break
        end
      end
      return order_by if order_by.present?

      @index_foreign_fields.each do |relation|
        foreign_name = relation[0]
        if foreign_name.in? belongs_to_or_has_one_relate_model_names
          foreign_model = foreign_name.to_s.classify.constantize
          foreign_table_name = foreign_model.table_name
          relation.drop(1).map do |foreign_field|
            if arrangement[:order_by] == "#{foreign_model.name.underscore}_#{foreign_field}"
              order_by = "#{foreign_table_name}.#{foreign_field}"
              break
            end
          end
        end
      end
      return order_by if order_by.present?

      "#{table_name}.created_at"
    end

    def full_keys_string
      primary_keys_string + (foreign_keys_string.present? ? (', ' + foreign_keys_string) : '')
    end

    def primary_keys_string
      @full_keys_tracking_string = []
      primary_keys_string = @index_fields.map do |v|
        unless EXCLUDE_KEYS_STRING.find_index(v)
          @full_keys_tracking_string << "#{table_name}.#{v}"
          "#{table_name}.#{v}"
        end
      end
      primary_keys_string.compact.join(', ')
    end

    def foreign_keys_string
      return '' unless @index_foreign_fields.present?
      @foreign_keys_string ||= @index_foreign_fields.map do |relation|
                                foreign_name = relation[0]
                                if foreign_name.in? belongs_to_or_has_one_relate_model_names
                                  foreign_model = foreign_name.to_s.classify.constantize
                                  foreign_table_name = foreign_model.table_name
                                  relation.drop(1).map do |foreign_field|
                                    unless EXCLUDE_KEYS_STRING.find_index(foreign_field)
                                      parsed_to_snake_case_foreign_field = "#{foreign_model.name.underscore}_#{foreign_field}"
                                      check_if_field_name_already_exist(parsed_to_snake_case_foreign_field)

                                      "#{foreign_table_name}.#{foreign_field} as #{foreign_model.name.underscore}_#{foreign_field}" 
                                    end
                                  end
                                end
                              end
      @foreign_keys_string.compact.join(', ')
    end

    def check_if_field_name_already_exist(parsed_to_snake_case_foreign_field)
      field_name_already_exist = @full_keys_tracking_string.find_index(parsed_to_snake_case_foreign_field)
      raise("Field name #{parsed_to_snake_case_foreign_field} already exist.") if field_name_already_exist
      @full_keys_tracking_string << parsed_to_snake_case_foreign_field
    end

    def full_search_string
      primary_search_string + (foreign_search_string.present? ? ' OR ' + foreign_search_string : '')
    end

    def primary_search_string
      primary_search_string = @index_fields.map do |v|
        unless EXCLUDE_SEARCH_STRING.find_index(v)
          "COALESCE(lower(#{table_name}.#{v}), '') LIKE '%#{arrangement[:keyword]}%'"
        end
      end
      primary_search_string.compact.join(' OR ')
    end

    def foreign_search_string
      return '' unless @index_foreign_fields.present?
      foreign_search_string = @index_foreign_fields.map do |relation|
                                foreign_name = relation[0]
                                if foreign_name.in? belongs_to_or_has_one_relate_model_names
                                  foreign_model = foreign_name.to_s.classify.constantize
                                  foreign_table_name = foreign_model.table_name
                                  relation.drop(1).map do |foreign_field|
                                    unless EXCLUDE_SEARCH_STRING.find_index(foreign_field)
                                      "COALESCE(lower(#{foreign_table_name}.#{foreign_field}), '') LIKE '%#{arrangement[:keyword]}%'" 
                                    end
                                  end
                                end
                              end
      foreign_search_string.compact.join(' OR ')
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
