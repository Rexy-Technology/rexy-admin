module RexyAdmin
  module Query
    # Old
    # # Add associations fields
    # def index_add_associations_fields_to_records associations, records
    #   # Convert records to hash and and association fields
    #   records.map do |record|
    #     hash_record = record.attributes.transform_keys(&:to_sym)
    #     add_associations_fields_to_record_recursively('', hash_record, associations)
    #   end
    # end

    # def add_associations_fields_to_record_recursively parents_encode_name, hash_record, associations
    #   associations.each do |association|
    #     next unless association[:fields].present?

    #     model_name = association[:model].model_name.singular
    #     added_parents_encode_name = "#{parents_encode_name}#{model_name}__"
    
    #     current_hash_record = add_associations_fields_to_record(added_parents_encode_name, hash_record, association)
    #     hash_record = current_hash_record
    #     has_child_associations = association.key?(:associations)
    #     next unless has_child_associations
    
    #     child_hash_record = add_associations_fields_to_record_recursively(added_parents_encode_name, hash_record, association[:associations])
    #     hash_record = child_hash_record
    #   end
    #   hash_record
    # end

    # def add_associations_fields_to_record(parents_encode_name, hash_record, association)
    #   parent_associations_array = parents_encode_name.split('__').map(&:to_sym)
    #   model_object = {}
    #   association[:fields].each do |association_field|
    #     key = "#{parents_encode_name}#{association_field}".to_sym
    #     model_object[association_field] = hash_record[key]
    #     hash_record.delete(key)
    #   end
    #   # Example: parents_encode_name = material__supplier__supplier_detail => hash_record[:material][:supplier][:supplier_detail] = model_object
    #   deep_set_hash(hash_record, model_object, parent_associations_array)
    #   hash_record
    # end

    # New
    # Add associations fields
    def index_add_associations_fields_to_records associations, records
      # Convert records to hash and and association fields
      records.map do |record|
        add_associations_fields_to_record_recursively(record, record, record.attributes.transform_keys(&:to_sym),  '', associations)
      end
    end

    def add_associations_fields_to_record_recursively(record, parent_record, parent_hash, parents_encode_name, associations)
      associations_hash = {}
      associations.each do |association|
        next unless association[:fields].present?

        model_name = association[:model].model_name.singular
        updated_parents_encode_name = "#{parents_encode_name}#{model_name}__"
        updated_parent_record = get_parent_records(parent_record, association)
        
        current_data = get_current_data(record, updated_parent_record, parent_hash, updated_parents_encode_name, association)
        # child_hash = get_child_hash(record, updated_parent_record, current_data, updated_parents_encode_name, association)

        current_data.merge(child_hash)
        key_name = association[:has_many] ? association[:model].model_name.plural : association[:model].model_name.singular
        associations_hash[key_name.to_sym] = current_data
      end
      associations_hash
    end

    def get_parent_records(parent_record, association)
      model_name = association[:has_many] ? association[:model].model_name.plural.to_sym
                                          : association[:model].model_name.singular.to_sym
      parent_record.send model_name                                                                           
    end

    def get_child_hash(record, current_data, parents_encode_name, association)
      return {} unless association.key?(:associations)

      association[:has_many] ? to_child_hash_array(record, current_data, parents_encode_name, association[:associations])\
                            : to_child_hash(record, current_data, parents_encode_name, association[:associations])
    end

    def to_child_hash_array(record, current_data, parents_encode_name, association[:associations])
      current_data.map { |d| add_associations_fields_to_record_recursively(record, parents_encode_name, d, association[:associations]) }
    end

    def to_child_hash(record, current_data, parents_encode_name, association[:associations])
      add_associations_fields_to_record_recursively(record, parents_encode_name, current_data, association[:associations])
    end


    # Current hash
    def get_current_data(record, parent_record, parent_hash, parents_encode_name, association)
      association[:has_many] ? to_hash_array(parent_record, parent_hash, association)\
                            : to_hash(record, parents_encode_name, association)
    end

    def to_hash_array(parent_record, parent_hash, association)
      model_name = association[:model].model_name.plural.to_sym
      hashs = parent_record.send(model_name)
      fields = association[:fields].map(&:to_s)
      serialize(hashs, fields)
    end

    def serialize records, fields
      return serialize_record(records, fields) unless records.is_a? Enumerable

      records.map { |record| serialize_record(record, fields) } 
    end

    def serialize_record record, fields
      serialized_record = {}
      record_to_h(record).each do |key, value|
        serialized_record[key.to_sym] = value if key.in? fields
      end
      serialized_record
    end

    def record_to_h record
      record.attributes.transform_keys(&:to_sym)
    end

    def to_hash(record, parents_encode_name, association)
      hash_record = record.attributes.transform_keys(&:to_sym)
      parent_associations_array = parents_encode_name.split('__').map(&:to_sym)
      model_object = {}
      association[:fields].each do |association_field|
        key = "#{parents_encode_name}#{association_field}".to_sym
        model_object[association_field] = hash_record[key]
      end
      model_object
    end
  end
end
