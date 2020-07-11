module RexyAdmin
  module Serializer
    class FormatHashRecords
      prepend SimpleCommand
  
      def initialize(association, model)
        @association = association
        @model = model
        @records = records
      end
  
      def call
        hash_records
      end

      def hash_records associations, records
        # Convert records to hash and and association fields
        records.map do |record|
          rejected_associations_fields_record = serialize(record, associations[:fields])
          associations_fields = associations_fields(record, record, record.attributes.transform_keys(&:to_sym),  '', associations)
          rejected_associations_fields_record.merge(associations_fields)
        end
      end

      def associations_fields(record, parent_record, parent_hash, parents_encode_name, associations)
        associations_hash = {}
        associations.each do |association|
          next unless association[:fields].present?
          data = get_data(record, parent_record, parent_hash, parents_encode_name, association)
          associations_hash[get_model_name(association).to_sym] = data
        end
        associations_hash
      end

      # Current hash
      def get_data(record, parent_record, parent_hash, parents_encode_name, association)
        model_name = association[:model].model_name.singular

        updated_parents_encode_name = "#{parents_encode_name}#{model_name}__"
        # has many ? [{}, {}, ...] : {}
        association[:has_many] ? to_hash_array(record, parent_record, parent_hash, updated_parents_encode_name, association)\
                              : to_hash(record, parent_record, parent_hash, updated_parents_encode_name, association)
      end

      def to_hash_array(record, parent_record, parent_hash, parents_encode_name, association)
        model_name = association[:model].model_name.plural.to_sym
        current_records = parent_record.send(model_name)
        current_records.map do |current_record|
          hash = serialize(current_record, association[:fields])
          child_hash = get_child_hash(record, current_record, hash, parents_encode_name, association)
          hash.merge(child_hash)
        end
      end
      
      def to_hash(record, parent_record, parent_hash, parents_encode_name, association)
        model_object = {}
        if association[:in_has_many_branch]
          model_name = association[:model].model_name.singular.to_sym
          current_record = parent_record.send(model_name)
          association[:fields].each do |association_field|
            model_object[association_field] = current_record.send(association_field)
          end
        else
          association[:fields].each do |association_field|
            hash_record = record.attributes.transform_keys(&:to_sym)
            key = "#{parents_encode_name}#{association_field}".to_sym
            model_object[association_field] = hash_record[key]
          end
        end
        
        updated_parent_record = parent_record.send(get_model_name(association))
        child_hash = get_child_hash(record, updated_parent_record, model_object, parents_encode_name, association)
        model_object.merge(child_hash)
      end
      
      def get_child_hash(record, parent_record, current_data, parents_encode_name, association)
        return {} unless association.key?(:associations)
        
        associations_fields(record, parent_record, current_data, parents_encode_name, association[:associations])
      end
      
      attr_accessor :association, :model, :records
    end
  end
end
