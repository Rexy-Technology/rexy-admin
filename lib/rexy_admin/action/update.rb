module RexyAdmin
  module Action
    # Update 
    def rexy_admin_update(id, params = {})
      action = :update
      raise "Action #{action.to_s} is not set in model #{model_name} yet." unless action.in? @actions
      
      params.merge!(id: id)
      execute_action(params, action)
    end
    
    def default_update params
      params = filter_params(params)
      record = find_by_id(params[:id])
      return {status: 'OK', result: {id: params[:id]}} if record.present? && record.update(params)
      
      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

    def filter_params params
      filtered_params = {}
      params.each do |key, value|
        key = key + '_attributes' if current_key_is_nested_attribute(key)
        filtered_params[key.to_sym] = value if key_in_column_names(key)
      end
      filtered_params
    end

    def current_key_is_nested_attribute(key)
      !key_in_column_names(key) && key_in_associations(key)
    end

    def key_in_column_names(key)
      key.to_s.in?(column_names + ["password"])
    end

    def key_in_associations(key)
      key.in?(associations)
    end

    def associations
      belongs_to_names = model.reflect_on_all_associations(:belongs_to).map(&:name)
      has_one_names = model.reflect_on_all_associations(:has_one).map(&:name)
      has_many_names = model.reflect_on_all_associations(:has_many).map(&:name)
      (belongs_to_names + has_one_names + has_many_names).uniq
    end

  end
end
