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
      check_if_associations_valid @index_associations
      # p '@index_associations: ' , @index_associations
      # p 'joins: ' , join_array
      # p 'select: ' , select_string
      # p 'search: ' , search_string
      records = joins(join_array).select(select_string)
      
      records, total_count = paginate_and_arrange_records records

      records = add_associations_fields_to_records(@index_associations, records)
      records = @index_after_action.call(records, @params[:current_admin]) if @index_after_action.present?
      result_if_success records, pagination.merge(total_count: total_count)
    end

   def check_if_associations_valid associations
      associations.map.with_index do |association, index|
        raise "Associations must be a array of hashes." unless association.is_a?(Hash)
        raise "Model is required." unless association.key?(:model)
        # raise "Association model must be a belongs_to or has_one." unless association[:model].model_name.singular.to_sym.in? belongs_to_or_has_one_relate_model_names
        (association[:fields].presence || []).each { |association_field| raise("Association fields not exists.") unless association_field.to_s.in? association[:model].column_names }
        # To add "fields" key as default
        formatted_association = {
          model: association[:model],
          fields: association[:fields].presence || []
        }
        formatted_association[:associations] = check_if_associations_valid(association[:associations]) if association.key?(:associations)
        formatted_association
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
      p 'search_string: ' , search_string
      p 'order_string: ' , order_string
      records = records.where(search_string).order(order_string).page(pagination[:page]).per(pagination[:per_page])
      [records, records.total_count]
    end

    def add_associations_fields_to_records associations, records
      records.map do |record|
        formatted_record('', associations, record.attributes.transform_keys(&:to_sym))
      end
    end
    
    def formatted_record parent_notation, associations, hash_record
      associations.each do |association|
        next unless association[:fields].present?
    
        parent_encode_name = "#{parent_notation}#{association[:model].model_name.singular}__"
    
        current_formatted_hash_record = formatted_hash_record(parent_encode_name, association, hash_record)
        hash_record = current_formatted_hash_record
        next unless association.key?(:associations)
    
        child_keys_string = formatted_record(parent_encode_name, association[:associations], hash_record)
        hash_record = child_keys_string
      end
      hash_record
    end
    
    def deep_set(hash, value, *keys)
      keys[0...-1].inject(hash) do |acc, h|
        acc.public_send(:[], h)
      end.public_send(:[]=, keys.last, value)
    end
    
    def formatted_hash_record parent_encode_name, association, hash_record
      model_object = {}
      association[:fields].each do |association_field|
        key = "#{parent_encode_name}#{association_field}".to_sym
        model_object[association_field] = hash_record[key]
        hash_record.delete(key)
      end
      deep_set(hash_record, model_object, *parent_encode_name.split('__').map(&:to_sym))
      hash_record
    end

    # Joins
    def to_model_name model
      model.model_name.singular.to_sym
    end
    
    def join_array
      to_join_array @index_associations
    end


    def to_join_array associations
      associations.map do |association|
        model = to_model_name(association[:model])
        next(model) unless association.key?(:associations)

        child_models = to_join_array(association[:associations])
        {model => [*child_models]}
      end
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

    def to_association_keys_string parent_notation , associations
      association_keys_string = associations.map do |association|
                                  next unless association[:fields].present?
                                  parent_encode_name = "#{parent_notation}#{association[:model].model_name.singular}__"
                                  
                                  current_keys_string = to_current_keys_string(association, parent_encode_name, parent_notation)
                                  next(current_keys_string) unless association.key?(:associations)
                                  
                                  child_keys_string = to_association_keys_string(parent_encode_name, association[:associations])
                                  current_keys_string + child_keys_string.presence || ''
                                end
      association_keys_string&.compact&.join
    end
    
    def to_current_keys_string association, parent_encode_name, parent_notation
      current_keys_string = association[:fields].map do |association_field|
        unless EXCLUDE_KEYS_STRING.find_index(association_field)
          current_encode_name = "#{parent_encode_name}#{association_field}"
          "#{association[:model].table_name}.#{association_field} as #{current_encode_name}" 
        end
      end
      current_keys_string = current_keys_string&.compact&.join(', ')
      is_outest_hash = parent_notation == ''
      current_keys_string.present? ? (is_outest_hash ? current_keys_string :  ', ' + current_keys_string) : ''
    end
    
    def association_keys_string
      return '' unless @index_associations.present?
      full_association_keys_string = to_association_keys_string('', @index_associations)
    
      full_association_keys_string.present? ? ', ' + full_association_keys_string : ''
    end

    # def association_keys_string
    #   return '' unless @index_associations.present?
    #   association_keys_string = @index_associations.map do |association|
    #                                 next unless association[:fields].present?
    #                                 association[:fields].map do |association_field|
    #                                   unless EXCLUDE_KEYS_STRING.find_index(association_field)
    #                                     "#{association[:model].table_name}.#{association_field} as #{association[:model].model_name.singular}__#{association_field}" 
    #                                   end
    #                                 end
    #                               end
    #   association_keys_string = association_keys_string&.compact&.join(', ')

    #   association_keys_string.present? ? ',  ' + association_keys_string : ''
    # end

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
