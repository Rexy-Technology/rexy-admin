require 'rexy_admin/serializer/format_hash_records'
require 'rexy_admin/serializer/helper'
require 'rexy_admin/serializer/join_and_include_array'
require 'rexy_admin/serializer/order_string'
require 'rexy_admin/serializer/search_string'
require 'rexy_admin/serializer/select_string'
require 'rexy_admin/serializer/validate_schema'

EXCLUDE_SEARCH_STRING = %w[id created_at password].freeze
EXCLUDE_KEYS_STRING = %w[password_digest created_at deleted_at].freeze
module RexyAdmin
  module Serializer 
    class Serializer
      prepend SimpleCommand
  
      def initialize(schema, params, before_query_conditions, after_query_lambda)
        @schema = initial_schema(schema)
        @params = params
        @before_query_conditions = before_query_conditions
        @after_query_lambda = after_query_lambda
      end

      def initial_schema(schema)
        raise "Please provide a model" if schema[:model].nil?

        fields = schema[:fields]&.presence&.uniq&.map(&:to_sym) || []
        search_fields = schema[:search_fields]&.presence&.uniq&.map(&:to_sym) || fields                                               

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
        validate_schema
        query_records
        execute_after_query_lambda
        paginate_and_arrange_records
        format_hash_records
        {
          records: hash_records,
          pagination: pagination.merge(total_count: total_count),
        }
      end
  
      def model
        @model ||= schema[:model]
      end
  
      def validate_schema
        @schema = ValidateSchema.call(schema, model).result
      end
  
      def query_records
        # deprecated select_string since now get associations fields by includes, just '.supplier.id'
        @records = model.joins(join_and_include_array)
                        .includes(join_and_include_array)
                        .where(before_query_conditions)
                        # .select(select_string)
      end

      def join_and_include_array 
        JoinAndIncludeArray.call(schema, model).result
      end
  
      def execute_after_query_lambda
        @records = @after_query_lambda.call(records, @params[:current_admin]) if @after_query_lambda.present?
      end
  
      def paginate_and_arrange_records
        # p 'search_string: ' , search_string
        # p 'order_string: ' , order_string
        records_before_limit = records.where(search_string).order(order_string)
        @total_count = records_before_limit.count
        @records = records_before_limit.page(pagination[:page]).per(pagination[:per_page])
      end

      def select_string
        SelectString.call(schema, model, arrangement).result
      end

      def search_string
        SearchString.call(schema, model, arrangement).result
      end

      def order_string
        OrderString.call(schema, model, arrangement).result
      end

      def format_hash_records
        @hash_records = FormatHashRecords.call(schema, model, records).result
      end

      def pagination
        {
          page: (@params[:page].presence || 1).to_i,
          per_page: (@params[:per_page].presence || 10).to_i
        }
      end
  
      def arrangement
        order_by = @params[:order_by]&.strip&.downcase
        order = @params[:order]&.upcase == 'ASCEND' ? 'ASC' : 'DESC'
        # order_by = column_names.include?(order_by_param) ? order_by_param : 'created_at'
        {
          order: order,
          order_by: order_by,
          keyword: @params[:keyword]
        }
      end
  
      attr_accessor :schema, :params, :before_query_conditions, :after_query_lambda, :records, :hash_records, :total_count
    end
  end
end
