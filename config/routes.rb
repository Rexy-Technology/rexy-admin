# RexyAdmin::Engine.routes.draw do
# end

# frozen_string_literal: true

class RexyAdminContrains
  def matches?(request)
    path = request.path
    objects = path.split('/').reject { |e| e.match?(/^\d+$|edit|new/) || e.blank? }
    object = objects.last
    model = object.classify&.constantize
    model&.included_modules&.include?(RexyAdmin)
  rescue StandardError
    false
  end
end

Rails.application.routes.draw do
  match 'rexy-admin/*path', to: 'rexy_admin#catch_all',
                 format: :json, via: %i[get post put delete patch],
                 constraints: RexyAdminContrains.new
end
