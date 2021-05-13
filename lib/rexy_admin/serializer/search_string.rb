# EXCLUDE_KEYS_STRING = %w[password_digest created_at deleted_at].freeze

module RexyAdmin
  module Serializer
    class SearchString
      prepend SimpleCommand
  
      def initialize(schema, model, arrangement)
        @schema = schema
        @model = model
        @arrangement = arrangement
      end
  
      def call
        search_string
      end

      def search_string
        all_search_fields_array.map do |v|
          # Example: "materials.id", "materials.supplier_id"
          unless v.split('.').last == 'id' || v.last(3) == '_id'
            if Rails.configuration.database_configuration[Rails.env]['adapter'] == "postgresql"
              "LOWER(unaccent(#{v})) ILIKE unaccent(:keyword)"
            else
              "COALESCE(lower(#{v}), '') LIKE :keyword"
            end
          end
        end.compact.join(' OR ')      
      end

      def all_search_fields_array
        search_fields_array_of_outest_model + all_search_fields_array_of_associations
      end

      def search_fields_array_of_outest_model
        schema[:search_fields].map do |search_field|
          "#{model.table_name}.#{search_field}" unless EXCLUDE_KEYS_STRING.find_index(search_field)
        end&.compact
      end

      def all_search_fields_array_of_associations
        search_fields_array_of_associations(schema[:associations])
      end
      
      def search_fields_array_of_associations(associations)
        associations.map do |association|
          current_search_fields_string = search_fields_array_of_association(association)
          next(current_search_fields_string) unless association.key?(:associations)

          child_search_fields_string = search_fields_array_of_associations(association[:associations]).presence || []
          [current_search_fields_string + child_search_fields_string]
        end&.compact.flatten
      end

      def search_fields_array_of_association(association)
        association[:search_fields].map do |search_field|
          unless EXCLUDE_KEYS_STRING.find_index(search_field)
            "#{association[:model].table_name}.#{search_field}" 
          end
        end&.compact
      end

      attr_accessor :schema, :model, :arrangement
    end
  end
end
