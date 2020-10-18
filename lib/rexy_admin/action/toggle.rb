# frozen_string_literal: true

module RexyAdmin
  module Action
    def rexy_admin_toggle(id, params = {})
      action = :toggle
      raise "Action #{action} is not set in model #{model_name} yet." unless action.in? @actions

      params.merge!(id: id)
      execute_action(params, action)
    end

    def default_toggle(params)
      record = find_by_id(params[:id])
      default_toggle_field = :active

      toggle_success = record.present? && record.toggle(@toggle_field.presence || default_toggle_field)

      if toggle_success && record.save
        return { status: 'OK', result: { id: params[:id] } }
      end

      { status: 'FAIL', result: "#{model_name.human} not exist." }
    end
  end
end
