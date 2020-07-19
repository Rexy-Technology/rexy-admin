module RexyAdmin
  module Action
    def rexy_admin_delete(id, params = {})
      action = :delete
      raise "Action #{action.to_s} is not set in model #{model_name} yet." unless action.in? @actions
      
      # Create body param "ids" if not exist in JSON body
      params[:ids] = [] unless params[:ids].present?
      # Push path variable "id" to ids
      params[:ids] << id
      # Filter uniq
      params[:ids] = params[:ids].uniq
      # If path variable "id" not exist, to_i will return 0
      # params[:ids] = params[:ids].reject {|id| id == 0 }
      params[:ids] = params[:ids].without 0

      execute_action(params, action)
    end

    def default_delete params
      records = where(id: params[:ids])
      return {status: 'OK', result: {status: 'OK'}} if params[:ids].count == records.count && records.destroy_all

      {status: 'FAIL', result: "#{model_name.human} not exist."}
    end

  end
end
