# frozen_string_literal: true

# rubocop:disable AbcSize
# rubocop:disable MethodLength
# rubocop:disable PerceivedComplexity
# rubocop:disable CyclomaticComplexity
# rubocop:disable ModuleLength
# rubocop:disable HandleExceptions, BlockLength
# rubocop:disable EvalWithLocation, Eval
# rubocop:disable ParameterLists
# rubocop:disable Style/Next
# rubocop:disable BlockNesting

EXCLUDE_KEYS = %w[password_digest created_at updated_at].freeze

module RexyAdmin
  module Variable
    def set_admin_table_columns(columns = [])
      @accessable_columns ||= columns.presence || columns_hash
    end

    def table_columns(custom_cols = [])
      @table_columns ||= build_columns(
        if custom_cols.present? 
          custom_cols.select do |col|
            @accessable_columns.include?(col.to_sym)
          end
        else
          @accessable_columns
        end
      )
    end

    def build_columns(custom_cols = [])
      columns = if custom_cols.present?
                  custom_cols.reduce({}) do |hash, col_name|
                    hash.merge!(col_name.to_s => columns_hash[col_name.to_s])
                  end
                else
                  columns_hash.except!(*EXCLUDE_KEYS)
                end
      sort_columns(map_types(columns))
    end

    def map_types(columns = {})
      columns.reduce([]) do |cols, (col_name, col_props)|
        aws_file_name = aws_key_image_field(col_name)
        cls = if defined_enums.key?(col_name)
                { type: 'enum', lookup: defined_enums[col_name].invert }
              elsif aws_file_name
                { type: 'image_url', title: aws_file_name.humanize }
              elsif col_props.type == :integer
                { type: 'numeric' }
              else
                { type: col_props.type }
              end
          cols << {
            field: col_name,
            title: col_name.to_s.humanize,
          }.merge!(cls)
      end
    end

    def set_custom_filters(custom_filters = [])
      # custom_filter = [ { name: 'Area', key: 'area', collection: [], scope:  }]
      @custom_filters = custom_filters
    end

    def sort_columns(columns)
      columns.sort_by { |col| col[:type] == 'image_url' ? -1 : 0 }
    end

    def aws_key_image_field(name)
      return false unless name.include?('aws_object_key')

      name.gsub('_aws_object_key_image', '')
    end



    def belongs_to_assosiations
      reflect_on_all_associations(:belongs_to)
    end

    def find_class_name_of_belongs_to_by_key(key)
      belongs_to_assosiations.select { |asso| asso.foreign_key == key }
                            .first
                            .class_name
    end

    def has_many_assosiations
      reflect_on_all_associations(:has_many)
    end

    def default_formdata
      belongs_to_keys = belongs_to_assosiations.map(&:foreign_key)
      columns_hash.inject({}) do |hash, value|
        key = value[0]
        type = value[1].type.to_s
        if defined_enums.key?(key)
          enum_keys = defined_enums[key].keys
                                        .map { |k| { label: k.camelize, value: k } }
          hash.merge(key.to_sym => { name: key.humanize,
                                    type: 'enum',
                                    collection: enum_keys })
        elsif belongs_to_keys.include?(key)
          klass = find_class_name_of_belongs_to_by_key(key).constantize
          hash.merge(key.to_sym => { name: key.humanize,
                                    type: 'belongs_to',
                                    collection: klass.parasite_entity_resource })
        else
          hash.merge(key.to_sym => { name: key.humanize,
                                    type: type })
        end
      end
    end

    def set_formdata(formdata = {})
      @formdata = formdata.presence || default_formdata
    end

    def get_formdata
      @formdata
    end
  end
end
