module RexyAdmin
  module Action
    def rexy_admin_delete(id, params = {})
      raise "Action delete is not set in model #{model_name} yet." unless :delete.in? @actions
      # Create body param "ids" if not exist in JSON body
      params[:ids] = [] unless params[:ids].present?
      # Push path variable "id" to ids
      params[:ids] << id
      # Filter uniq
      params[:ids] = params[:ids].uniq
      # If path variable "id" not exist, to_i will return 0
      params[:ids] = params[:ids].reject {|id| id == 0 }

      return custom_delete(params) if @delete_params_checker.present?

      default_delete(params)
    end

    def default_delete params
      records = @delete_custom_query.where(id: params[:ids])
      return {status: 'OK', result: {status: 'OK'}} if params[:ids].count == records.count && records.destroy_all

      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

    def custom_delete params 
       custom_action(params, @delete_params_checker, @delete_context, @delete_command, 'default_delete')
    end

  end
end
