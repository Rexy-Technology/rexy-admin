EXCLUDE_KEYS_STRING = %w[password_digest deleted_at].freeze

module RexyAdmin
  module Serializer
    class SearchString
      prepend SimpleCommand
  
      def initialize(association, model, arrangement)
        @association = association
        @model = model
        @arrangement = arrangement
      end
  
      def call
        search_string
      end

      def search_string
        all_search_fields_array_of_outest_model + all_search_fields_array_of_associations
      end

      def all_search_fields_array_of_outest_model
        association[:fields].map do |v|
          "#{table_name}.#{v}" unless EXCLUDE_KEYS_STRING.find_index(v)
        end.compact.join(', ')
      end
  
      def all_search_fields_array_of_associations
        search_fields_array_of_associations(associations).map do |v|
          # Example: "materials.id", "materials.supplier_id"
          unless v.split('.').last == 'id' || v.last(3) == '_id'
            "COALESCE(lower(#{v}), '') LIKE '%#{arrangement[:keyword]}%'"
          end
        end.compact.join(' OR ').present? ? (', ' + full_association_search_fields_string) : ''
      end
      
      def search_fields_array_of_associations(associations)
        associations[:associations].map do |association|
          current_search_fields_string = search_fields_array_of_association(association)
          next(current_search_fields_string) unless association.key?(:associations)

          child_search_fields_string = search_fields_array_of_associations(association[:associations]).presence || []
          current_search_fields_string + child_search_fields_string
        end&.compact&.join
      end

      def search_fields_array_of_association(association)
        association[:search_fields].map do |association_field|
          unless EXCLUDE_KEYS_STRING.find_index(association_field)
            "#{association[:model].table_name}.#{association_field}" 
          end
        end
      end

      attr_accessor :association, :model, :arrangement
    end
  end
end
