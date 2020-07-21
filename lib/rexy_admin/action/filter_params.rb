module RexyAdmin
  module Action
    def filter_params params
      filtered_params = {}
      params.each do |key, value|
        if key_in_column_names(key)
          filtered_params[key.to_sym] = value
        elsif key_in_associations(key)
          filtered_params[(key + '_attributes').to_sym] = value
        end
      end
      filtered_params
    end

    def key_in_column_names(key)
      key.to_s.in?(column_names + ["password"])
    end

    def key_in_associations(key)
      key.to_sym.in?(associations)
    end

    def associations
      belongs_to_names = reflect_on_all_associations(:belongs_to).map(&:name)
      has_one_names = reflect_on_all_associations(:has_one).map(&:name)
      has_many_names = reflect_on_all_associations(:has_many).map(&:name)
      (belongs_to_names + has_one_names + has_many_names).uniq
    end
  end
end
