module RexyAdmin
  module Serializer
    class SelectString
      prepend SimpleCommand
  
      def initialize(association, model, arrangement)
        @association = association
        @model = model
        @arrangement = arrangement
      end
  
      def call
        select_string
      end

      def select_string
        to_association_select_fields_string('', associations)
      end
      
      # If a relation is has_many, not select it's field and it's predecessor => not sort, search them; only show them.
      def to_association_select_fields_string parents_encode_name , associations
        associations.map do |association|
          next if association[:in_has_many_branch] || !association[:fields].present?
          
          model_name = association[:model].model_name.singular
          added_parents_encode_name = "#{parents_encode_name}#{model_name}__"
          current_select_fields_string = to_current_select_fields_string(association, added_parents_encode_name, parents_encode_name)
          next(current_select_fields_string) unless association.key?(:associations)

          child_select_fields_string = to_association_select_fields_string(added_parents_encode_name, association[:associations]).presence || ''
          current_select_fields_string + child_select_fields_string
        end&.compact&.join
      end
      
      def to_current_select_fields_string association, added_parents_encode_name, parents_encode_name
        current_select_fields_string = association[:fields].map do |association_field|
          unless EXCLUDE_KEYS_STRING.find_index(association_field)
            current_encode_name = "#{added_parents_encode_name}#{association_field}"
            "#{association[:model].table_name}.#{association_field} as #{current_encode_name}" 
          end
        end
        current_select_fields_string = current_select_fields_string&.compact&.join(', ')
        is_outest_hash = parents_encode_name == ''
        current_select_fields_string.present? ? (is_outest_hash ? current_select_fields_string :  ', ' + current_select_fields_string) : ''
      end

      attr_accessor :association, :model, :arrangement
    end  
  end
end
