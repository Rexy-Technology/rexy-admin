require 'rexy_admin/serializer/helper'

module RexyAdmin
  module Serializer 
    class ValidateSchema
      prepend SimpleCommand
  
      def initialize(schema, model)
        @schema = schema
        @model = model
      end
  
      def call
        # no need to validate associations of the outest model
        schema[:associations] = validate_associations(model, schema[:associations], false)
        # init some data for the outest model
        schema
      end
  
      def validate_associations(parent_model, associations, in_has_many_branch)
        associations.map.with_index do |association, index|
          validate_association(parent_model, association)
          formatted_association(parent_model, associations, in_has_many_branch, association)
        end
      end
  
      def validate_association(parent_model, association)
        raise "Associations must be a array of hashes." unless association.is_a?(Hash)
        raise "Model is required." unless association.key?(:model)
        raise("#{association[:model].to_s} not having any relation with #{parent_model.to_s}.") unless
          (
            association[:model].model_name.singular.to_sym.in?(Helper.belongs_to_or_has_one_relate_model_names(parent_model)) || 
            association[:model].model_name.plural.to_sym.in?(Helper.has_many_model_names(parent_model))
          )
        (association[:fields].presence || []).each { |association_field| raise("Association fields not exists.") unless association_field.to_s.in? association[:model].column_names }
      end
  
      def formatted_association(parent_model, associations, in_has_many_branch, association)
        has_many = Helper.is_has_many_relation?(parent_model, association[:model])
        # Once a relation is has_many, not select, not sort, not search it's field and it's predecessor's fields => only show.
        # Once set it to true, it's predecessor will always receive parameter true
        in_has_many_branch = has_many || in_has_many_branch
        # Fields
        fields = association[:fields].presence&.uniq&.map(&:to_sym) || []
        search_fields = association[:search_fields].presence&.uniq&.map(&:to_sym).reject{|key| key == :id} || fields
        # Initialize data
        formatted_association = {
          model: association[:model],
          fields: fields,
          search_fields: search_fields,
          has_many: has_many,
          in_has_many_branch: in_has_many_branch,
        }
        formatted_association[:associations] = validate_associations(association[:model], association[:associations], in_has_many_branch) if association.key?(:associations)
        formatted_association
      end
  
      attr_accessor :schema, :model
    end
  end
end
