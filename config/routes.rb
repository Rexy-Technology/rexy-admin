# RexyAdmin::Engine.routes.draw do
# end

# frozen_string_literal: true

class RexyAdminContrains
  def matches?(request)
    model = request.params["model"]&.classify&.constantize
    model&.included_modules&.include?(RexyAdmin)
  rescue StandardError
    false
  end
end

Rails.application.routes.draw do
  match '/rexy-admin/*path', to: 'rexy_admin#catch_all',
                 format: :json, via: %i[get post put delete patch],
                 constraints: RexyAdminContrains.new
  post 'rexy-admin/login', to: 'rexy_admin#login'
end
