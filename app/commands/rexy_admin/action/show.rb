# frozen_string_literal: true

module RexyAdmin
  module Action
    class Show
      prepend SimpleCommand

      def initialize(params = {})
        p 'hehe1: ' , params
        @params = params
      end

      def call
        record = params[:show_custom_query].joins(show_join_array).select(show_select_string).find_by_id(params[:id])
        show_check_if_associations_valid
        record = add_associations_fields_to_record(record) if record.present?
        
        record  = params[:show_after_action].call(record, params[:current_admin]) if record.present? && params[:show_after_action].present?
      end

      def show_check_if_associations_valid
        params[:show_associations].each_with_index do |association, index|
          raise "Associations must be a array of hashes." unless association.is_a?(Hash)
          raise "Field model is required." unless association.key?(:model)
          raise "Association model must be a belongs_to or has_one." unless association[:model].model_name.singular.to_sym.in? belongs_to_or_has_one_relate_model_names
          params[:show_associations][index][:fields] = association[:fields].presence || []
          (association[:fields].presence || []).each { |association_field| raise("Association fields not exists.") unless association_field.to_s.in? association[:model].column_names }
        end
      end

      def add_associations_fields_to_record record
        to_h_record = record.attributes.transform_keys(&:to_sym)
        params[:show_associations].each do |association|
          model_object = {}
          association[:fields].each do |association_field|
            foreign_field = "#{association[:model].model_name.singular}__#{association_field}"
            model_object[association_field] = record.send foreign_field
            to_h_record.delete(foreign_field.to_sym)
          end
          to_h_record[association[:model].model_name.singular.to_sym] = model_object
        end
        to_h_record
      end

      # Joins
      def show_join_array
        params[:show_associations].map { |association_field| association_field[:model].model_name.singular.to_sym }
      end

      def belongs_to_or_has_one_relate_model_names
        belongs_to_names = reflect_on_all_associations(:belongs_to).map(&:name)
        has_one_names = reflect_on_all_associations(:has_one).map(&:name)
        (belongs_to_names + has_one_names).uniq
      end

      # Select
      def show_select_string
        show_primary_keys_string + show_association_keys_string
      end

      def show_primary_keys_string
        primary_keys_string = params[:show_fields].map do |v|
          "#{table_name}.#{v}" unless EXCLUDE_KEYS_STRING.find_index(v)
        end
        primary_keys_string.compact.join(', ')
      end

      def show_association_keys_string
        return '' unless params[:show_associations].present?
        association_keys_string = params[:show_associations].map do |association|
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

      attr_accessor :params
    end
  end
end
