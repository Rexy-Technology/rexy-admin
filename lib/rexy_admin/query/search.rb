module RexyAdmin
  module Query
    def search_string
      search_string = keys_array.map do |v|
                        # Example: "materials.id", "materials.supplier_id"
                        unless v.split('.').last == 'id' || v.last(3) == '_id'
                          "COALESCE(lower(#{v}), '') LIKE '%#{arrangement[:keyword]}%'"
                        end
                      end
      search_string.compact.join(' OR ')
    end
  end
end
