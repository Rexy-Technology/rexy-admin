module RexyAdmin
  module Query
    
    def index_join_array
      to_join_array self, @index_associations
    end

    def to_join_array parent_model, associations
      associations.map do |association|
        model_name = association[:has_many] ? association[:model].model_name.plural.to_sym : association[:model].model_name.singular.to_sym
        next(model_name) unless association.key?(:associations)
          
        child_model_names = to_join_array(association[:model], association[:associations])
        {model_name => [*child_model_names]}
      end
    end

  end
end
