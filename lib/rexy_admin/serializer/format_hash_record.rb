require 'rexy_admin/serializer/helper'

module RexyAdmin
  module Serializer
    class FormatHashRecord
      prepend SimpleCommand
  
      def initialize(schema, model, record)
        @schema = schema
        @model = model
        @record = record
      end
  
      def call
        hash_record(record)
      end

      def hash_record(record)        
        hash_record = Helper.serialize(record, schema[:fields])
        associations_fields = associations_fields(record, record, record.attributes.transform_keys(&:to_sym), schema[:associations])
        hash_record.merge(associations_fields)
      end

      def associations_fields(record, parent_record, parent_hash, associations)
        associations_hash = {}
        associations.each do |association|
          next unless association[:fields].present?

          data = get_data(record, parent_record, parent_hash, association)
          associations_hash[Helper.model_name(association).to_sym] = data
        end
        associations_hash
      end

      # Current hash
      def get_data(record, parent_record, parent_hash, association)
        model_name = association[:model].model_name.singular

        # has many ? [{}, {}, ...] : {}
        association[:has_many] ? to_hash_array(record, parent_record, parent_hash, association)\
                              : to_hash(record, parent_record, parent_hash, association)
      end

      def to_hash_array(record, parent_record, parent_hash, association)
        model_name = association[:model].model_name.plural.to_sym
        current_records = parent_record.send(model_name)
        current_records.map do |current_record|
          hash = Helper.serialize(current_record, association[:fields])
          child_hash = get_child_hash(record, current_record, hash, association)
          hash.merge(child_hash)
        end
      end
      
      def to_hash(record, parent_record, parent_hash, association)
        model_object = {}
        model_name = association[:model].model_name.singular.to_sym
        current_record = parent_record.send(model_name)
        association[:fields].each do |association_field|
          model_object[association_field] = current_record.send(association_field)
        end
        
        updated_parent_record = parent_record.send(Helper.model_name(association))
        child_hash = get_child_hash(record, updated_parent_record, model_object, association)
        model_object.merge(child_hash)
      end
      
      def get_child_hash(record, parent_record, current_data, association)
        return {} unless association.key?(:associations)
        
        associations_fields(record, parent_record, current_data, association[:associations])
      end
      
      attr_accessor :schema, :model, :record
    end
  end
end
