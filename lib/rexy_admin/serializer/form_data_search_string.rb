# EXCLUDE_KEYS_STRING = %w[password_digest created_at deleted_at].freeze

module RexyAdmin
  module Serializer
    class FormDataSearchString
      prepend SimpleCommand
  
      def initialize(schema, model, params)
        @schema = schema
        @model = model
        @params = params
      end

      def call
        search_string
      end

      def search_string
        search_fields_string_of_outest_model + all_search_fields_string_of_associations
      end

      def search_fields_string_of_outest_model
        search_fields_string = ''
        id_param = params["#{model.table_name.singularize}_id"]
        if id_param.present?
          search_fields_string = "#{model.table_name}.id = #{id_param}" if id_param.present?
        else
          search_fields_string = schema[:search_fields].map do |search_field|
            # example: like suppliers.name
            search_field_string = "#{model.table_name}.#{search_field}"
            # example: like supplier_keyword
            keyword_param_string = model.table_name.singularize + '_keyword'
  
            # TODO: add search in postgres too
            "COALESCE(lower(#{search_field_string}), '') LIKE '%#{params[keyword_param_string]}%'"
          end&.compact.join(' OR ')
        end
        
        "(#{search_fields_string})"
      end

      def all_search_fields_string_of_associations
        search_fields_string = search_fields_string_of_associations(schema[:associations], schema[:model])
        search_fields_string.present? ? " AND (#{search_fields_string})" : ''
      end
      
      def search_fields_string_of_associations(associations, parent_model)
        associations.map do |association|
          next unless searchable?(parent_model)

          current_search_fields_string = search_fields_string_of_association(association)
          next(current_search_fields_string) unless association.key?(:associations)

          child_search_fields_string = search_fields_string_of_associations(association[:associations], association[:model]).presence || ''
          child_search_fields_string = child_search_fields_string.present? ? " AND (#{child_search_fields_string})" : ''

          current_search_fields_string + child_search_fields_string
        end&.compact.join(' OR ')
      end

      def searchable?(parent_model)
        # only searchable if parent_model_id is present => already get the parent model options
        # example: supplier is parent of materials. So to search materials, we have to choose the supplier first
        # => supplier_id must be present

        params["#{parent_model.table_name.singularize}_id"].present?
      end

      def search_fields_string_of_association(association)
        search_fields_string = (association[:search_fields] + [:id]).map do |search_field|
          # example: like suppliers.name
          search_field_string = "#{association[:model].table_name}.#{search_field}"
          param_suffix = search_field == :id ? '_id' : '_keyword'
          # example: like supplier_keyword
          keyword_param_string = association[:model].table_name.singularize + param_suffix
          value = params[keyword_param_string]
          next if search_field == :id && value.nil?

          # TODO: add search in postgres too
          "COALESCE(lower(#{search_field_string}), '') LIKE '%#{value}%'"
        end&.compact.join(' OR ')
        "(#{search_fields_string})"
      end

      attr_accessor :schema, :model, :params
    end
  end
end
