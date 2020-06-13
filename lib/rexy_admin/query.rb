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
      records = @index_command.call(@params.merge(arrangement: arrangement)).result.page(pagination[:page]).per(pagination[:per_page])
      result_if_success records, pagination.merge(total_count: records.total_count)
    end

    def records_filtered_by_default
      check_if_associations_valid
      # p '@index_associations: ' , @index_associations
      # p 'joins: ' , join_array
      # p 'select: ' , select_string
      # p 'search: ' , search_string
      records = joins(join_array).select(select_string)
      records, total_count = paginate_and_arrange_records records

      records = add_associations_fields_to_records records
      records = @index_after_action.call(records, @params[:current_admin]) if @index_after_action.present?
      result_if_success records, pagination.merge(total_count: total_count)
    end

    def check_if_associations_valid
      @index_associations.each_with_index do |association, index|
        raise "Associations must be a array of hashes." unless association.is_a?(Hash)
        raise "Field model is required." unless association.key?(:model)
        raise "Association model must be a belongs_to or has_one." unless association[:model].model_name.singular.to_sym.in? belongs_to_or_has_one_relate_model_names
        @index_associations[index][:fields] = association[:fields].presence || []
        (association[:fields].presence || []).each { |association_field| raise("Association fields not exists.") unless association_field.to_s.in? association[:model].column_names }
      end
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
      records = records.where(search_string).order(order_string).page(pagination[:page]).per(pagination[:per_page])
      [records, records.total_count]
    end

    def add_associations_fields_to_records records
      records.map do |record|
        to_h_record = record.attributes.transform_keys(&:to_sym)
        @index_associations.each do |association|
          model_object = {}
          association[:fields].each do |association_field|
            foreign_field = "#{association[:model].model_name.singular}__#{association_field}"
            p '1: ' , record
            model_object[association_field] = record.send foreign_field
            to_h_record.delete(foreign_field.to_sym)
          end
          to_h_record[association[:model].model_name.singular.to_sym] = model_object
        end
        to_h_record
      end
    end

    # Joins
    def join_array
      @index_associations.map { |association_field| association_field[:model].model_name.singular.to_sym }
    end

    def belongs_to_or_has_one_relate_model_names
      belongs_to_names = reflect_on_all_associations(:belongs_to).map(&:name)
      has_one_names = reflect_on_all_associations(:has_one).map(&:name)
      (belongs_to_names + has_one_names).uniq
    end

    # Select
    def select_string
      primary_keys_string + association_keys_string
    end

    def primary_keys_string
      primary_keys_string = @index_fields.map do |v|
        "#{table_name}.#{v}" unless EXCLUDE_KEYS_STRING.find_index(v)
      end
      primary_keys_string.compact.join(', ')
    end

    def association_keys_string
      return '' unless @index_associations.present?
      association_keys_string = @index_associations.map do |association|
                                    association[:fields].present? ? association[:fields].map do |association_field|
                                                                      unless EXCLUDE_KEYS_STRING.find_index(association_field)
                                                                        "#{association[:model].table_name}.#{association_field} as #{association[:model].model_name.singular}__#{association_field}" 
                                                                      end
                                                                    end
                                                                  :  nil
                                  end
      association_keys_string = association_keys_string&.compact&.join(', ')

      association_keys_string.present? ? ',  ' + association_keys_string : ''
    end

    # Search
    def search_string
      primary_search_string + association_search_string
    end

    def primary_search_string
      primary_search_string = @index_fields.map do |v|
        unless EXCLUDE_SEARCH_STRING.find_index(v)
          "COALESCE(lower(#{table_name}.#{v}), '') LIKE '%#{arrangement[:keyword]}%'"
        end
      end
      primary_search_string.compact.join(' OR ')
    end

    def association_search_string
      return '' unless @index_associations.present?
      association_search_string = @index_associations.map do |association|
                                    association[:fields].present? ? association[:fields].map do |association_field|
                                                                      unless EXCLUDE_SEARCH_STRING.find_index(association_field)
                                                                        "COALESCE(lower(#{association[:model].table_name}.#{association_field}), '') LIKE '%#{arrangement[:keyword]}%'"
                                                                      end
                                                                    end
                                                                  : nil
                                  end
      association_search_string = association_search_string&.compact&.join(' OR ')
      association_search_string.present? ? ' OR ' + association_search_string : ''
    end

    # Order
    def keys_array
      [primary_keys_array + association_keys_array].flatten
    end

    def primary_keys_array
      primary_keys_array = @index_fields.map do |v|
        "#{table_name}.#{v}" unless EXCLUDE_KEYS_STRING.find_index(v)
      end
      primary_keys_array.compact
    end

    def association_keys_array
      return [] unless @index_associations.present?
      @association_keys_array ||= @index_associations.map do |association|
                                      association[:fields].present? ? association[:fields].map do |association_field|
                                                                        unless EXCLUDE_KEYS_STRING.find_index(association_field)
                                                                          "#{association[:model].table_name}.#{association_field}"
                                                                        end
                                                                      end
                                                                    : nil
                                   end
      @association_keys_array&.select{ |association| association.present? }
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


      return @parsed_to_pluralize_order_by if association_order_by_valid

      "#{table_name}.created_at"
    end

      
    def association_order_by_valid
      order_by = arrangement[:order_by].to_s
      array_order_by = order_by.split('.')
      return false unless array_order_by.length >= 2

      association_model_table_name = array_order_by[-2].pluralize
      association_model_field = array_order_by[-1]
      @parsed_to_pluralize_order_by = "#{association_model_table_name}.#{association_model_field}"

      # Example : "customer.product.name" => "products.name"
      @parsed_to_pluralize_order_by.in?(keys_array)
    end

    # Etc
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
