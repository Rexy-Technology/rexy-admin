module RexyAdmin
  module Query
    def search_string
      search_string = keys_array.map do |v|
                        # Example: "materials.id", "materials.supplier_id"
                        unless v.split('.').last == 'id' || v.last(3) == '_id'
                          "COALESCE(lower(materials.code), '') LIKE '%844%'"
                          # Material.joins(:supplier => :supplier_detail).where("COALESCE(lower(supplier_details.real_bank_name), '') LIKE '%844%'")
                        end
                      end
      search_string.compact.join(' OR ')
    end
  end
end
