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

EXCLUDE_SEARCH_STRING = %w[id password].freeze
EXCLUDE_KEYS_STRING = %w[password_digest deleted_at].freeze
SQL_DEFAULT_DATE_FORMAT = '%Y-%m-%d'
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
      @index_associations = check_if_associations_valid self, @index_associations
      # p '@index_associations: ' , @index_associations
      p 'joins: ' , index_join_array
      p 'select: ' , index_select_string
      records = joins(index_join_array).select(index_select_string)
      records = @index_after_query.call(records, @params[:current_admin], @params) if @index_after_query.present?
      records, total_count = paginate_and_arrange_records records
      hash_records = index_add_associations_fields_to_records(@index_associations, records)
      hash_records = @index_after_action.call(hash_records, @params[:current_admin], @params) if @index_after_action.present?
      result_if_success hash_records, pagination.merge(total_count: total_count)
    end

    def check_if_associations_valid parent_model, associations
      associations.map.with_index do |association, index|
        raise "Associations must be a array of hashes." unless association.is_a?(Hash)
        raise "Model is required." unless association.key?(:model)
        raise("#{association[:model].to_s} not belongs_to or has_one #{parent_model.to_s}.") unless
          association[:model].model_name.singular.to_sym.in?(belongs_to_or_has_one_relate_model_names(parent_model))
        (association[:fields].presence || []).each { |association_field| raise("Association fields not exists.") unless association_field.to_s.in? association[:model].column_names }
        # To add "fields = []" key as default
        formatted_association = {
          model: association[:model],
          fields: association[:fields].presence || []
        }
        formatted_association[:associations] = check_if_associations_valid(association[:model], association[:associations]) if association.key?(:associations)
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
      # p '======>search_string: ' , search_string
      # p '@index_search_fields: ' , @index_search_fields
      # p 'order_string: ' , order_string
      records = records.where(search_string).order(order_string).page(pagination[:page]).per(pagination[:per_page])
      [records, records.total_count]
    end

    # Add associations fields
    def index_add_associations_fields_to_records associations, records
      # Convert records to hash and and association fields
      records.map do |record|
        hash_record = record.attributes.transform_keys(&:to_sym)
        add_associations_fields_to_record_recursively('', hash_record, associations)
      end
    end

    def add_associations_fields_to_record_recursively parents_encode_name, hash_record, associations
      associations.each do |association|
        next unless association[:fields].present?

        model_name = association[:model].model_name.singular
        added_parents_encode_name = "#{parents_encode_name}#{model_name}__"
    
        current_hash_record = add_associations_fields_to_record(added_parents_encode_name, hash_record, association)
        hash_record = current_hash_record
        has_child_associations = association.key?(:associations)
        next unless has_child_associations
    
        child_hash_record = add_associations_fields_to_record_recursively(added_parents_encode_name, hash_record, association[:associations])
        hash_record = child_hash_record
      end
      hash_record
    end

    def add_associations_fields_to_record(parents_encode_name, hash_record, association)
      parent_associations_array = parents_encode_name.split('__').map(&:to_sym)
      model_object = {}
      association[:fields].each do |association_field|
        key = "#{parents_encode_name}#{association_field}".to_sym
        model_object[association_field] = hash_record[key]
        hash_record.delete(key)
      end
      # Example: parents_encode_name = material__supplier__supplier_detail => hash_record[:material][:supplier][:supplier_detail] = model_object
      deep_set_hash(hash_record, model_object, parent_associations_array)
      hash_record
    end

    # Joins
    def to_model_name parent_model, model
      model.model_name.singular.to_sym
    end
    
    def index_join_array
      to_join_array self, @index_associations
    end

    def to_join_array parent_model, associations
      associations.map do |association|
        model = to_model_name(parent_model, association[:model])
        next(model) unless association.key?(:associations)

        child_models = to_join_array(association[:model], association[:associations])
        {model => [*child_models]}
      end
    end

    def belongs_to_or_has_one_relate_model_names model
      belongs_to_names = model.reflect_on_all_associations(:belongs_to).map(&:name)
      has_one_names = model.reflect_on_all_associations(:has_one).map(&:name)
      (belongs_to_names + has_one_names).uniq
    end

    def has_many_model_names model
      model.reflect_on_all_associations(:has_many).map(&:name)
    end

    # Select
    def index_select_string
      primary_keys_string(@index_fields) + association_keys_string(@index_associations)
    end

    def primary_keys_string fields
      primary_keys_string = fields.map do |v|
        "#{table_name}.#{v}" unless EXCLUDE_KEYS_STRING.find_index(v)
      end
      primary_keys_string.compact.join(', ')
    end
        
    def association_keys_string associations
      return '' unless associations.present?
      full_association_keys_string = to_association_keys_string('', associations)
    
      full_association_keys_string.present? ? ', ' + full_association_keys_string : ''
    end

    def to_association_keys_string parents_encode_name , associations
      association_keys_string = associations.map do |association|
                                  next unless association[:fields].present?
                                  model_name = association[:model].model_name.singular
                                  added_parents_encode_name = "#{parents_encode_name}#{model_name}__"
                                  
                                  current_keys_string = to_current_keys_string(association, added_parents_encode_name, parents_encode_name)
                                  next(current_keys_string) unless association.key?(:associations)
                                  
                                  child_keys_string = to_association_keys_string(added_parents_encode_name, association[:associations])
                                  current_keys_string + child_keys_string.presence || ''
                                end
      association_keys_string&.compact&.join(', ')
    end
    
    def to_current_keys_string association, added_parents_encode_name, parents_encode_name
      current_keys_string = association[:fields].map do |association_field|
        unless EXCLUDE_KEYS_STRING.find_index(association_field)
          current_encode_name = "#{added_parents_encode_name}#{association_field}"
          "#{association[:model].table_name}.#{association_field} as #{current_encode_name}" 
        end
      end
      current_keys_string = current_keys_string&.compact&.join(', ')
      is_outest_hash = parents_encode_name == ''
      current_keys_string.present? ? (is_outest_hash ? current_keys_string :  ', ' + current_keys_string) : ''
    end

    def search_string
      search_string = keys_array.map do |v|
                        # Example: "materials.id", "materials.supplier_id"
                        is_id_field = (v.split('.').last == 'id' || v.last(3) == '_id')
                        not_in_search_fields = v.split('.').first == table_name && !v.split('.').last.to_sym.in?(@index_search_fields)
                        next if is_id_field || not_in_search_fields

                        model = v.split('.').first.classify.constantize
                        column = model.columns_hash[v.split('.').last]

                        unless column.type == :date
                          next "COALESCE(lower(#{v}), '') LIKE '%#{arrangement[:keyword]}%'"
                        end

                        keyword_is_date = arrangement[:keyword]&.match(RexyAdmin.date_regrex)

                        if keyword_is_date
                          # 20-05-1999 => 1999-05-20
                          date = arrangement[:keyword].to_date
                          date_string = date.strftime(SQL_DEFAULT_DATE_FORMAT)
                          "COALESCE(lower(#{v}), '') LIKE '%#{date_string}%'"
                        end
                      end
      search_string.compact.join(' OR ')
    end

    # Order
    def keys_array
      index_select_string.split(', ').map do |v|
        # Example: remove all " as " to get an associations array
        if ' as '.in? v
          index = v.index ' as '
          next(v[0..index-1])
        end
        v
      end
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
    def is_has_many_relation? parent_model, model
      return false unless parent_model.present?

      model_name = model.model_name.singular.to_sym
      belongs_to_or_has_one_relate_model_names = belongs_to_or_has_one_relate_model_names(parent_model)
      return !model_name.in?(belongs_to_or_has_one_relate_model_names)
    end

    def deep_set_hash(hash, value, keys)
      # {
      #   :a => {
      #     :b => {
      #       c: 'd'
      #     }
      #   }
      # }
      # ==> 
      # {
      #   :b => {
      #     c: 'd'
      #   }
      # }
      #  Use inject to get to the deepest field, then set value to it.
      keys[0...-1].inject(hash) do |deeper_hash, h|
        deeper_hash[h]
      end[keys.last] = value
    end

    def deep_get_instance(instance, *keys)
      keys[0...-1].inject(instance) do |deeper_instance, h|
        deeper_instance.send h
      end.send keys.last
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
