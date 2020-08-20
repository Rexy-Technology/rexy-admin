module RexyAdmin
  module Serializer
    class SelectString
      prepend SimpleCommand
  
      def initialize(schema, model, arrangement)
        @schema = schema
        @model = model
        @arrangement = arrangement
      end
  
      def call
        select_string
      end

      def select_string
        all_select_fields_array
      end

      def all_select_fields_array
        select_fields_array_of_outest_model + (all_select_fields_array_of_associations.present? ? (', ' + all_select_fields_array_of_associations) : '')
      end

      def select_fields_array_of_outest_model
        schema[:fields].map do |v|
          "#{model.table_name}.#{v}" unless EXCLUDE_KEYS_STRING.find_index(v)
        end&.compact&.join(', ')
      end

      def all_select_fields_array_of_associations
        select_fields_array_of_associations(schema[:associations])
      end
      
      # If a relation is has_many, not select it's field and it's predecessor => not sort
      def select_fields_array_of_associations associations
        associations.map do |association|
          next if !association[:fields].present?
          
          model_name = association[:model].model_name.singular
          current_select_fields_string = select_fields_array_of_association(association)
          next(current_select_fields_string) unless association.key?(:associations)

          child_select_fields_string = select_fields_array_of_associations(association[:associations]).presence || ''
          current_select_fields_string + (child_select_fields_string.present? ? (', ' + child_select_fields_string) : '')
        end&.compact&.join(', ')
      end
      
      def select_fields_array_of_association association
        association[:fields].map do |v|
          "#{association[:model].table_name}.#{v}" unless EXCLUDE_KEYS_STRING.find_index(v)
        end&.compact&.join(', ')
      end

      attr_accessor :schema, :model, :arrangement
    end  
  end
end
