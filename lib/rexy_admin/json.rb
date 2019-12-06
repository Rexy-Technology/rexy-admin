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

module RexyAdmin
  module Json
    def parasite_render_table_json(records, pagination, params)
      {
        metadata: table_columns,
        records: records,
        # records: compute_record_for_table(records),
        # entity: table_name,
        # custom_filters: get_custom_filters,
        # pagination: pagination,
        # params: params.except(:controller, :path, :action)
      }
    end

    def compute_record_for_table(records)
      records.reduce([]) do |rs, rc|
        rs << table_columns.keys.reduce({}) do |record, key|
          key_method = table_columns[key][:method] || key
          record.merge!(key.to_sym => rc.send(key_method))
        end.merge!(actions: rc.table_actions)
      end
    end

    def parasite_render_form_json(record)
      {
        data: record,
        formdata: get_formdata
      }
    end

    def add_actions_to_records(records)
      records.map(&:add_actions)
    end
  end
end