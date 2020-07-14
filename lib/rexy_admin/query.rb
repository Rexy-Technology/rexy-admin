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

require 'rexy_admin/query/add_associations'
require 'rexy_admin/query/helper'
require 'rexy_admin/query/joins'
require 'rexy_admin/query/order'
require 'rexy_admin/query/search'
require 'rexy_admin/query/select'

# EXCLUDE_KEYS_STRING = %w[password_digest created_at deleted_at].freeze
module RexyAdmin
  module Query
    def set_params(params)
      @params = params
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

    def rexy_admin_query(params = {})
      set_params params
      return @index_command.present? ? records_filtered_by_custom_command : records_filtered_by_default
    end

    def records_filtered_by_custom_command
      if @index_params_checker.present?
        params_checker_cmd = @index_params_checker.call(params: @params, context: @index_context.merge(current_admin: @params[:current_admin]))
        return {status: 'FAIL', result: params_checker_cmd.errors} if params_checker_cmd.failure?
        @params = params_checker_cmd.result
      end 
      records = @index_command.call(@params.merge(arrangement: arrangement)).result.page(pagination[:page]).per(pagination[:per_page])
      result_if_success records, pagination.merge(total_count: records.total_count)
    end

    def records_filtered_by_default
      @index_associations = check_if_associations_valid(self, @index_associations, false)
      records = joins(index_join_array)
               .includes(index_join_array)
               .select(index_select_string)
      # records = @index_after_query.call(records, @params[:current_admin]) if @index_after_query.present?
      records, total_count = paginate_and_arrange_records records
      hash_records = index_add_associations_fields_to_records(@index_associations, records)
      hash_records = @index_after_action.call(hash_records, @params[:current_admin]) if @index_after_action.present?
      result_if_success hash_records, pagination.merge(total_count: total_count)
    end

    def check_if_associations_valid(parent_model, associations, in_has_many_branch)
      associations.map.with_index do |association, index|
        check_if_association_valid(parent_model, association)
        formatted_association(parent_model, associations, in_has_many_branch, association)
      end
    end

    def check_if_association_valid(parent_model, association)
      raise "Associations must be a array of hashes." unless association.is_a?(Hash)
      raise "Model is required." unless association.key?(:model)
      raise("#{association[:model].to_s} not having any relation with #{parent_model.to_s}.") unless
        (
          association[:model].model_name.singular.to_sym.in?(belongs_to_or_has_one_relate_model_names(parent_model)) || 
          association[:model].model_name.plural.to_sym.in?(has_many_model_names(parent_model))
        )
      (association[:fields].presence || []).each { |association_field| raise("Association fields not exists.") unless association_field.to_s.in? association[:model].column_names }
    end

    def formatted_association(parent_model, associations, in_has_many_branch, association)
      has_many = is_has_many_relation?(parent_model, association[:model])
      # Once a relation is has_many, not select, not sort, not search it's field and it's predecessor's fields => only show.
      # Once set it to true, it's predecessor will always receive parameter true
      in_has_many_branch = has_many || in_has_many_branch
      # Initialize data
      formatted_association = {
        model: association[:model],
        fields: association[:fields].presence || [],
        search_fields: association[:search_fields].presence || association[:fields].presence || [],
        has_many: has_many,
        in_has_many_branch: in_has_many_branch,
      }
      formatted_association[:associations] = check_if_associations_valid(association[:model], association[:associations], in_has_many_branch) if association.key?(:associations)
      formatted_association
    end

    def result_if_success records, pagination
      {
        status: 'OK', result: rexy_admin_render_table_json(
          records, 
          pagination
        )
      }
    end

    def paginate_and_arrange_records records
      # p 'search_string: ' , search_string
      # p 'order_string: ' , order_string
      records = records.where(search_string).order(order_string).page(pagination[:page]).per(pagination[:per_page])
      [records, records.total_count]
    end

  end
end
