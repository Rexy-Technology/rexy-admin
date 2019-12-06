# frozen_string_literal: true

class RexyAdminController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

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
  end

  def index
    path = request.path
    paths = path.split('/')
    return show if paths.last == 'edit'
    return new if paths.last == 'new'

    # result = if objects.length > 1
    #            source_object = objects[-2]
    #            source_id = path.split('/')[-2].to_i
    #            model.parasite_query(params.permit!.merge(source_object:{ name: source_object,
    #                                                                      id: source_id }))
    #          else
    #            model.parasite_query(params.permit!)
    #          end
    result = model.parasite_query(params.permit!)
    render json: result
  end

  def create
    result = model.parasite_create(params)
    return render json: result if result == 'OK'

    render json: result, status: 422
  end

  def show
    result = model.parasite_show(record_id)
    return render json: model.parasite_render_form_json(result) if result.present?

    render json: 'NO RECORD', status: 422
  end

  def new
    result = model.get_table_data
    render json: { form_data: result }
  end

  def delete
    result = model.parasite_delete(record_id)
    return render json: result if result == 'OK'

    render json: result, status: 422
  end

  def update
    result = model.parasite_update(record_id, params.permit!)
    return render json: 'OK' if result == 'OK'

    render json: result, status: 422
  end

  def toggle_active
    result = model.parasite_toggle_active(record_id)
    return render json: result if result == 'OK'

    render json: result, status: 422
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
    @record_id ||= path_request.split('/')
                               .select { |e| e.match?(/^\d+$/) }
                               .last
                               .to_i
  end
end
