# RexyAdmin::Engine.routes.draw do
# end

# frozen_string_literal: true

CUSTOM_PREFIX_URL = 'extra-gate'
class RexyAdminContrains
  def matches?(request)
    # will fix this if add multiple models (users/posts/comments)
    # model = request.path
    #                .split('/')&
    #                .reject { |e| e.match?(/^\d+$|edit|new/) || e.blank? }&
    #                .last&
    #                .classify&
    #                .constantize

    # p '1: ' , request.path
    # p '2: ' , request.path.split('/')
    # p '3: ' , request.path.split('/')[2]
    # p '4: ' , request.path.split('/')[2].classify
    # p '5: ' , request.path.split('/')[2].classify&.constantize

    string_model = request.path.split('/')[2]

    return false if string_model == CUSTOM_PREFIX_URL
      
    model = request.path.split('/')[2].classify&.constantize 
    model&.included_modules&.include?(RexyAdmin)
  rescue => e
    false
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
  post '/rexy-admin/login', to: 'rexy_admin#login', constraints: UseRexyAdminLogin.new
end
