module RexyAdmin
  class FilterParams
    prepend SimpleCommand

    def initialize(outest_model, params)
      @outest_model = outest_model
      @params = params
    end

    def call
      filtered_params = {}
      params.each do |key, value|
        next unless key_is_valid(key)

        formatted_key = key_in_column_names(outest_model, key) ? key.to_sym : "#{key}_attributes"
        value = filtered_value(key, value) if value.is_a?(Array) && key_in_associations(outest_model, key)
        filtered_params[formatted_key] = value 
      end
      filtered_params
    end

    def key_is_valid(key)
      key_in_column_names(outest_model, key) || key_in_associations(outest_model, key)
    end

    def filtered_value parent_key, parent_array
      parent_array.map do |parent_hash|
        filtered_hash = {}
        parent_hash.each do |key, value|
          parent_model = parent_key.classify.constantize
          next unless child_key_is_valid(parent_model, key)
          
          formatted_key = key_in_column_names(parent_model, key) ? key.to_sym : "#{key}_attributes"
          p 'value: ' , value
          p 'condi1: ' , value.is_a?(Array)
          p 'condi2: ' , key_in_associations(parent_model, key)
          p 'condi3: ' , value.is_a?(Array) && key_in_associations(parent_model, key)
          value = filtered_value(key, value) if value.is_a?(Array) && key_in_associations(parent_model, key)
          filtered_hash[formatted_key] = value 
        end
        filtered_hash
      end
    end

    def child_key_is_valid(parent_model, child_key)
      key_in_column_names(parent_model, child_key) || key_in_associations(parent_model, child_key)
    end

    def key_in_column_names(model, key)
      key.to_s.in?(model.column_names + ["password"])
    end

    def key_in_associations(model, key)
      key.to_sym.in?(associations(model))
    end

    def associations(model)
      belongs_to_names = model.reflect_on_all_associations(:belongs_to).map(&:name)
      has_one_names = model.reflect_on_all_associations(:has_one).map(&:name)
      has_many_names = model.reflect_on_all_associations(:has_many).map(&:name)
      (belongs_to_names + has_one_names + has_many_names).uniq
    end

    attr_accessor :params, :outest_model
  end
end
