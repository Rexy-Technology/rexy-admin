module RexyAdmin
  module Serializer
    class OrderString
      prepend SimpleCommand
  
      def initialize(association, model, arrangement)
        @association = association
        @model = model
        @arrangement = arrangement
      end
  
      def call
        order_string
      end

      def order_string
        "#{order_by_string} #{arrangement[:order]}"
      end

      def order_by_string
        order_by_in_params_string.presence || default_order_by_string
      end

      def default_order_by_string
        "#{model.table_name}.created_at"
      end

      def order_by_in_params_string
        order_by = arrangement[:order_by].to_s
        array_order_by = order_by.split('.')
        # 'materials.code' is valid
        return false unless array_order_by.length >= 2

        # Example : "customer.product.name" => "products.name"
        formatted_order_by_string = "#{array_order_by[-1]}.#{array_order_by[-2].pluralize}"

        formatted_order_by_string.in?(all_fields_array) ? formatted_order_by_string : nil
      end

      def all_fields_array
        fields_array_of_associations(associations)
      end
      
      def fields_array_of_associations(associations)
        associations.map do |association|
          current_fields_string = fields_array_of_association(association)
          next(current_fields_string) unless association.key?(:associations)

          child_fields_string = fields_array_of_associations(association[:associations]).presence || []
          current_fields_string + child_fields_string
        end&.compact&.join
      end

      def fields_array_of_association(association)
        association[:fields].map do |association_field|
          unless EXCLUDE_KEYS_STRING.find_index(association_field)
            "#{association[:model].table_name}.#{association_field}" 
          end
        end
      end

    attr_accessor :association, :model, :arrangement
    end
  end
end
