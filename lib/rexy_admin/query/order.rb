module RexyAdmin
  module Query
    def keys_array
      index_select_string.split(', ').map do |v|
        # Example: remove all " as " to get an associations array
        if ' as '.in? v
          index = v.index ' as '
          next(v[0..index-1])
        end
        v
      end
    end

    def order_string
      "#{order_by_string} #{arrangement[:order]}"
    end

    def order_by_string
      order_by = ''
      @index_fields.each do |v|
        if arrangement[:order_by] == v.to_s
          order_by = "#{table_name}.#{arrangement[:order_by]}" 
          break
        end
      end
      return order_by if order_by.present?

      return @parsed_to_pluralize_order_by if association_order_by_valid

      "#{table_name}.created_at"
    end

    def association_order_by_valid
      order_by = arrangement[:order_by].to_s
      array_order_by = order_by.split('.')
      return false unless array_order_by.length >= 2

      association_model_table_name = array_order_by[-2].pluralize
      association_model_field = array_order_by[-1]
      @parsed_to_pluralize_order_by = "#{association_model_table_name}.#{association_model_field}"

      # Example : "customer.product.name" => "products.name"
      @parsed_to_pluralize_order_by.in?(keys_array)
    end
  end
end
