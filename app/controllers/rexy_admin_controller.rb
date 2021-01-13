# frozen_string_literal: true

class RexyAdminController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token
  before_action :authenticate, except: [:login]

  def login
    cmd = AuthenticateAdmin.call(params)
    if cmd.success?
      render json: cmd.result
    else
      render json: cmd.errors, status: 422
    end
  end

  def authenticate
    unless admin_token.present? && current_admin.present?
      render json: { authentication: 'Not Authorized.' }, status: 401
    end
  end

  def admin_token
    @admin_token ||= JsonWebToken.decode(request.headers['RexyAdmin-Authorization'])
  end

  def current_admin
    @current_admin ||= RexyAdmin.auth_model.auth_query.find_by_id(admin_token[:admin_id])
    # @current_admin ||= model.auth_query.find_by_id(admin_token[:admin_id])
  end

  def catch_all
    if request.get?
      get_action
    elsif request.post?
      create
    elsif request.patch?
      toggle_active
    elsif request.put?
      update
    elsif request.delete?
      delete
    end
  # rescue => e
  #   render json: {
  #   "errors": {
  #     "message": e,
  #     "details": {}
  #   }
  # }, status: 422
  end

  def get_action
    if paths.last == 'edit'
      show
    elsif paths.last == 'new'
      new
    elsif paths[-2] == 'query'
      query
    elsif paths.length == 3
      index
    end
  end

  # Get actions
  def show
    result = model.rexy_admin_show(record_id, params.merge(current_admin: current_admin).permit!)
    render_json(result)
  end

  def new
    result = model.rexy_admin_get_form_data(params.merge(current_admin: current_admin).permit!)
    render_json(result)
  end

  def query
    result = model.rexy_admin_query(params.merge(current_admin: current_admin, request_path: request_path).permit!)
    render_json(result)
  end

  def index
    result = model.rexy_admin_index(params.merge(current_admin: current_admin).permit!)
    render_json(result)
  end

  def create
    result = model.rexy_admin_create(params.merge(current_admin: current_admin).permit!)
    render_json(result)
  end

  def toggle_active
    result = model.rexy_admin_toggle(record_id, params.merge(current_admin: current_admin).permit!)
    render_json(result)
  end

  def update
    result = model.rexy_admin_update(record_id, params.merge(current_admin: current_admin).permit!)
    render_json(result)
  end

  def delete
    result = model.rexy_admin_delete(record_id, params.merge(current_admin: current_admin).permit!)
    render_json(result)
  end

  private

  def request_path
    @request_path = request.path
  end

  def model
    # @model ||= request_path.split('/')
    #                        .reject { |e| e.match?(/^\d+$|edit|new/) || e.blank? }
    #                        .last
    #                        .classify
    #                        .constantize

    @model ||= request_path.split('/')[2].classify&.constantize
  end

  def record_id
    @record_id ||= request_path.split('/')\
                               .reject { |e| e.match?(/^edit|new/) || e.blank? }\
                               .last\
                               .to_i
  end

  def paths
    @paths ||= request_path.split('/')
  end

  def render_json(result)
    return render(json: result[:result]) if result[:status] == 'OK'

    render(json: get_errors(result), status: 422)
  end

  def get_errors(result)
    unless result[:result].is_a?(String)
      return {
        errors: result[:result][:errors][0]
      }
    end

    {
      errors: {
        message: result[:result],
        details: {}
      }
    }
  end

  def action
    if request.get?
      path = request.path
      paths = path.split('/')

      return 'show' if paths.last == 'edit'
      return 'get_form_data' if paths.last == 'new'
      return 'form' if paths.last == 'form'
    elsif request.post?
      'create'
    elsif request.patch?
      'toggle_active'
    elsif request.put?
      'update'
    elsif request.delete?
      'delete'
    end
  end

  def auth_query
    action = action
    action_auth_query = instance_variable_get("@#{action}_auth_query")

    action_auth_query.presence ||
      @general_auth_query ||
      RexyAdmin.auth_model.where('')
  end
end
