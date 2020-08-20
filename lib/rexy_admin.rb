require 'rexy_admin/engine'
require 'rexy_admin/variable'
require 'rexy_admin/query'
require 'rexy_admin/form'
require 'rexy_admin/json'
require 'rexy_admin/action'
require 'rexy_admin/serializer'

module RexyAdmin
  def self.included(base)
    puts '------>Rexy Admin Including'
    base.extend(Variable)
    # base.set_admin_table_columns
    base.extend(Query)
    base.extend(Form)
    base.extend(Json)
    base.extend(Action)
    # base.set_custom_filters
    # base.set_actions
    # base.set_formdata

    base.use_actions
  end

  mattr_accessor :auth_model, :use_rexy_admin_login, :login_field
  @@use_rexy_admin_login = false
  @@login_field = :email
end
