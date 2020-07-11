require 'rexy_admin/serializer/format_hash_records'
require 'rexy_admin/serializer/helper'
require 'rexy_admin/serializer/join_and_include_array'
require 'rexy_admin/serializer/order_string'
require 'rexy_admin/serializer/search_string'
require 'rexy_admin/serializer/select_string'
require 'rexy_admin/serializer/validate_association'

EXCLUDE_KEYS_STRING = %w[password_digest created_at deleted_at].freeze

module RexyAdmin
  module Serializer 
    class Serializer
      prepend SimpleCommand
  
      def initialize(association, params, before_query_conditions, after_query_lambda)
        @association = initial_association(association)
        @params = params
        @before_query_conditions = before_query_conditions
        @after_query_lambda = after_query_lambda
      end

      def initial_association(association)
        p 'jeje5: ' , association
        raise "Please provide a model" if association[:model].nil?

        fields = (association[:fields]&.uniq&.presence || model.column_names ) - EXCLUDE_KEYS_STRING
        search_fields = association[:search_fields]&.uniq&.presence || fields                                               

        {
          model: association[:model],
          associations: association[:associations].presence || [],
          fields: fields,
          search_fields: search_fields,
          has_many: false,
          in_has_many_branch: false
        }
      end
  
      def call
        validate_association
        query_records
        execute_after_query_lambda
        paginate_and_arrange_records
        # format_hash_records
        p 'jeje5: ' , records
        {
          status: 'OK', result: {
            # records: hash_records,
            records: records,
            pagination: pagination,
          }
        }
      end
  
      def model
        @model ||= association[:model]
      end
  
      def validate_association
        @association = ValidateAssociation.call(association, model).result
      end
  
      def query_records
        p 'jeje3: ' ,join_and_include_array
        p 'jeje4: ' ,before_query_conditions
        # p 'jeje5: ' ,select_string
        @records = model.joins(join_and_include_array)
                        .includes(join_and_include_array)
                        .where(before_query_conditions)
                        # .select(select_string)
      end

      def join_and_include_array 
        JoinAndIncludeArray.call(association, model).result
      end
  
      def execute_after_query_lambda
        @records = @after_query_lambda.call(records, @params[:current_admin]) if @after_query_lambda.present?
      end
  
      def paginate_and_arrange_records
        p 'search_string: ' , search_string
        # p 'order_string: ' , order_string
        @records = records.where(search_string)
        # @records = records.where(search_string).order(order_string)
        # @records = records.where(search_string).order(order_string).page(pagination[:page]).per(pagination[:per_page])
        @total_count = records.total_count
      end

      def select_string
        SelectString.call(association, model, arrangement).result
      end

      def search_string
        SearchString.call(association, model, arrangement).result
      end

      def order_string
        OrderString.call(association, model, arrangement).result
      end

      def format_hash_records
        @hash_records = FormatHashRecords.call(association, model, records).result
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
  
      attr_accessor :association, :params, :before_query_conditions, :after_query_lambda, :records
    end
  end
end
