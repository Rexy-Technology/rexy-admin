require 'rexy_admin/serializer/format_hash_records'
require 'rexy_admin/serializer/format_hash_record'
require 'rexy_admin/serializer/helper'
require 'rexy_admin/serializer/join_and_include_array'
require 'rexy_admin/serializer/order_string'
require 'rexy_admin/serializer/search_string'
require 'rexy_admin/serializer/form_data_search_string'
require 'rexy_admin/serializer/select_string'
require 'rexy_admin/serializer/validate_schema'
require 'rexy_admin/serializer/my_error'

EXCLUDE_SEARCH_STRING = %w[id password].freeze
EXCLUDE_KEYS_STRING = %w[password_digest deleted_at].freeze
EXCLUDE_QUERY_PARAMS = %w[page per_page order_by order].freeze

module RexyAdmin
  module Serializer 
    class Serializer
      prepend SimpleCommand
  
      def initialize(
        schema: {},
        params: {},
        context: {},
        params_checker: nil,
        after_query: nil,
        many: false,
        paginate: false,
        is_form_data_type: false
      )
        @schema = initial_schema(schema)
        @params = params
        @context = context
        # raise "Please provide a params_checker when using after_query" if after_query.present? && !params_checker.present?
        @params_checker = params_checker
        @after_query = after_query
        @query_params = get_query_params

        @many = many
        @paginate = paginate
        @is_form_data_type = is_form_data_type
      end

      def initial_schema(schema)
        raise "Please provide a model" unless schema[:model].present?

        fields = schema[:fields]&.presence&.uniq&.map(&:to_sym) || schema[:model].column_names
        search_fields = schema[:search_fields].present? ? schema[:search_fields]&.presence&.uniq&.map(&:to_sym)&.reject{|key| key == :id} : fields                                               
        {
          model: schema[:model],
          associations: schema[:associations].presence || [],
          fields: fields,
          search_fields: search_fields,
          has_many: false,
          in_has_many_branch: false
        }
      end

      def call
        many ? hash_records : hash_record
      end

      def hash_records
        validate_schema
        return nil unless params_valid
        
        query_records
        paginate_and_arrange_records
        result = {
          records: formated_hash_records
        }
        
        result[:pagination] = pagination.merge(total_count: total_count) if paginate
        result
      end

      def hash_record
        validate_schema
        return nil unless params_valid

        query_record
        return nil unless record_exist

        {
          record: formated_hash_record
        }
      end
  
      def model
        @model ||= schema[:model]
      end
  
      def validate_schema
        @schema = ValidateSchema.call(schema, model).result
      end

      def params_valid
        return true unless params_checker.present?

        cmd = params_checker.call(params: query_params, context: context.merge(current_admin: query_params[:current_admin]))
        if cmd.failure?
          errors.add(:errors, cmd.errors[:errors][0])
          return nil
        end
        
        @params.merge!(cmd.result)
        true
      end

      def get_query_records
        return @get_query_records if @get_query_records.present?
        
        @get_query_records = model.includes(join_and_include_array)
                                  .references(join_and_include_array)
        # .distinct(:id)
        
        @get_query_records = after_query.call(@get_query_records, params) if after_query.present?
        @get_query_records
      end

      def query_records
        # deprecated select_string since now get associations fields by includes, just '.supplier.id'
        
        # p "========>get_query_records: ", get_query_records
        @records = get_query_records
      end
  
      def query_record
        @records = get_query_records
        @record = records.first

        @record_exist = record.present?
        errors.add(:errors, {
            "message": "#{model.model_name.human} not exist.",
            "details": {}
        }) unless record_exist
      end

      def join_and_include_array 
        JoinAndIncludeArray.call(schema, model).result
      end
  
      def paginate_and_arrange_records
        # p 'records: ' , records
        # p 'search_string: ' , search_string
        # # p 'order_string: ' , order_string
        records_before_limit = records.where(search_string).order(order_string)
        @total_count = records_before_limit.length
        @records = records_before_limit.page(pagination[:page]).per(pagination[:per_page]) if paginate
      end

      # def select_string
      #   SelectString.call(schema, model, arrangement).result
      # end

      def search_string
        is_form_data_type ? FormDataSearchString.call(schema, model, params).result
                          : SearchString.call(schema, model, arrangement).result
      end

      def order_string
        OrderString.call(schema, model, arrangement).result
      end

      def formated_hash_records
        FormatHashRecords.call(schema, model, records).result
      end

      def formated_hash_record
        return {} unless record.present?
        
        FormatHashRecord.call(schema, model, record).result
      end

      def pagination
        {
          page: (@params[:page].presence || 1).to_i,
          per_page: (@params[:per_page].presence || 10).to_i
        }
      end
  
      def arrangement
        order_by = @params[:order_by]&.strip&.downcase&.presence || ''
        order = @params[:order]&.upcase == 'ASCEND' ? 'ASC' : 'DESC'
        {
          order: order,
          order_by: order_by,
          keyword: @params[:keyword]
        }
        
      end

      def get_query_params
        params.reject { |key, value| key.in?(EXCLUDE_QUERY_PARAMS) }
      end

      attr_accessor :schema,
                    :params,
                    :query_params,
                    :after_query,
                    :many,
                    :paginate,
                    :records,
                    :record,
                    :total_count,
                    :params_checker,
                    :context,
                    :record_exist,
                    :is_form_data_type
    end
  end
end
