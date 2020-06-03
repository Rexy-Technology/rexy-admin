# RexyAdmin::Engine.routes.draw do
# end

# frozen_string_literal: true

class RexyAdminContrains
  def matches?(request)
    p 'hehe1: ' , request.path
    model = request.path.split('/')&.reject { |e| e.match?(/^\d+$|edit|new/) || e.blank? }&.last&.classify&.constantize
    p 'hehe2'
    model&.included_modules&.include?(RexyAdmin)
  rescue => e
    e
  end
end

class UseRexyAdminLogin
  def matches?(request)
    RexyAdmin.use_rexy_admin_login
  end
end

Rails.application.routes.draw do
  match '/rexy-admin/*path', to: 'rexy_admin#catch_all',
                 format: :json, via: %i[get post put delete patch],
                 constraints: RexyAdminContrains.new
  post 'rexy-admin/login', to: 'rexy_admin#login', constraints: UseRexyAdminLogin.new
end
