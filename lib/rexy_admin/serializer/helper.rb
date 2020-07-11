module RexyAdmin
  module Serializer
    module Helper
      extend self

      def to_model_name parent_model, model
        model.model_name.singular.to_sym
      end

      def model_name association
        association[:has_many] ? association[:model].model_name.plural.to_sym
                              : association[:model].model_name.singular.to_sym
      end

      def belongs_to_or_has_one_relate_model_names model
        belongs_to_names = model.reflect_on_all_associations(:belongs_to).map(&:name)
        has_one_names = model.reflect_on_all_associations(:has_one).map(&:name)
        (belongs_to_names + has_one_names).uniq
      end

      def has_many_model_names model
        model.reflect_on_all_associations(:has_many).map(&:name)
      end

      # Etc
      def is_has_many_relation? parent_model, child_model
        return false unless parent_model.present?

        model_name = child_model.model_name.singular.to_sym
        belongs_to_or_has_one_relate_model_names = belongs_to_or_has_one_relate_model_names(parent_model)
        return !model_name.in?(belongs_to_or_has_one_relate_model_names)
      end

      def serialize records, fields
        return serialize_record(records, fields) unless records.is_a? Enumerable

        records.map { |record| serialize_record(record, fields) } 
      end

      def serialize_record record, fields
        serialized_record = {}
        record_to_h(record).each do |key, value|
          serialized_record[key.to_sym] = value if key.in?(fields) || key.to_s.in?(fields)
        end
        serialized_record
      end

      def record_to_h record
        record.attributes.transform_keys(&:to_sym)
      end
    end

  end
end
