module RexyAdmin
  class FilterParams
    prepend SimpleCommand

    def initialize(
      model: nil,
      params: {},
      destroy_untracking_records: true
    )
      @model = model
      @params = params
      @destroy_untracking_records = destroy_untracking_records
    end

    def call
      filter_hash(model, params)
    end

    def filter_hash(model, hash)
      hash.each_with_object({}) do |param, hash|
        key, value = param
        next unless key_is_valid?(model, key)

        param_is_nested_object = key_in_has_many_associations?(model, key)
        param_is_array = value.is_a?(Array)
        param_may_contains_nested_object = param_is_nested_object && param_is_array
        
        if param_may_contains_nested_object
          value = filter_array(key, value) if param_is_nested_object
        end

        key = param_is_nested_object ? "#{key}_attributes" : key.to_sym
        
        hash[key] = value 
      end
    end

    def filter_array(key, array)
      array.map do |param|
        next param unless param.is_a?(Hash)
        
        model = key.to_s.classify.constantize
        filter_hash(model, param)
      end
    end

    def key_is_valid?(model, key)
      key_in_column_names?(model, key) || key_in_associations?(model, key)
    end

    def key_in_column_names?(model, key)
      key.to_s.in?(model.column_names + ["password"])
    end

    def key_in_associations?(model, key)
      key.to_sym.in?(associations(model))
    end

    def key_in_has_many_associations?(model, key)
      has_many_names = model.reflect_on_all_associations(:has_many).map(&:name)

      key.to_sym.in?(has_many_names)
    end

    def associations(model)
      belongs_to_names = model.reflect_on_all_associations(:belongs_to).map(&:name)
      has_one_names = model.reflect_on_all_associations(:has_one).map(&:name)
      has_many_names = model.reflect_on_all_associations(:has_many).map(&:name)
      
      (belongs_to_names + has_one_names + has_many_names).uniq
    end

    attr_accessor :params, :model
  end
end


# arr > hash > params
# author: {
#   name: 'a'
#   age: 41,
#   books: [
#     {
#       title: 'a'
#     }
#   ]
# }

# a

# {
#   "post_hash_tags_attributes":  [
#     {
#       "id": 2211,
#       "hash_tag": "h",
#       "_destroy": true
#     }
#   ]
# }
# a.update b