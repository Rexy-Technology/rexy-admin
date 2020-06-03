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
    render json: { authentication: 'Not Authorized.' }, status: 401 unless admin_token.present? && current_admin.present?
  end

  def admin_token
    @admin_token ||= JsonWebToken.decode(request.headers['RexyAdmin-Authorization'])
  end

  def current_admin
    @current_admin ||= RexyAdmin.auth_model.where(model.auth_query)
                                           .find_by_id(admin_token[:admin_id])
  end

  def catch_all
    if request.get?
      index
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

  def index
    path = request.path
    paths = path.split('/')
    return show if paths.last == 'edit'
    return new if paths.last == 'new'
    # result = if objects.length > 1
    #            source_object = objects[-2]
    #            source_id = path.split('/')[-2].to_i
    #            model.rexy_admin_query(params.permit!.merge(source_object:{ name: source_object,
    #                                                                      id: source_id }))
    #          else
    #            model.rexy_admin_query(params.permit!)
    #          end
    result = model.rexy_admin_query((params.merge(current_admin: current_admin).permit!))
    return render json: result[:result] if result[:status] == 'OK'

    render json: {
      "errors": {
        "message": result[:result],
        "details": {}
      }
    }

  end

  def show
    result = model.rexy_admin_show(record_id, (params.merge(current_admin: current_admin).permit!))
    return render json: result[:result] if result[:status] == 'OK'

    render json: {
      "errors": {
        "message": result[:result],
        "details": {}
      }
    }
  end

  def new
    result = model.get_form_data
    render json: { form_data: result }
  end

  def toggle_active
    result = model.rexy_admin_toggle(record_id, (params.merge(current_admin: current_admin).permit!))
    return render json: result[:result] if result[:status] == 'OK'

    render json: {
      "errors": {
        "message": result[:result],
        "details": {}
      }
    }, status: 422
  end

  def create
    result = model.rexy_admin_create(params.merge(current_admin: current_admin).permit!)
    return render json: result[:result] if result[:status] == 'OK'

    render json: {
      "errors": {
        "message": result[:result],
        "details": {}
      }
    }, status: 422
  end

  def delete
    result = model.rexy_admin_delete(record_id, (params.merge(current_admin: current_admin).permit!))
    return render json: result[:result] if result[:status] == 'OK'

    render json: {
      "errors": {
        "message": result[:result],
        "details": {}
      }
    }, status: 422
  end

  def update
    result = model.rexy_admin_update(record_id, (params.merge(current_admin: current_admin).permit!))
    return render json: result[:result] if result[:status] == 'OK'

    render json: {
      "errors": {
        "message": result[:result],
        "details": {}
      }
    }, status: 422
  end

  private

  def path_request
    @path_request = request.path
  end

  def model
    @model ||= path_request.split('/')
                           .reject { |e| e.match?(/^\d+$|edit|new/) || e.blank? }
                           .last
                           .classify
                           .constantize
  end

  def record_id
    @record_id ||= path_request.split('/')\
                    .reject { |e| e.match?(/^edit|new/) || e.blank? }\
                    .last\
                    .to_i
  end

end 
