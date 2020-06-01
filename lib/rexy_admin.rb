require 'rexy_admin/engine'
require 'rexy_admin/variable'
require 'rexy_admin/query'
require 'rexy_admin/json'
require 'rexy_admin/action'



module RexyAdmin
  def self.included(base)
    puts '------>Rexy Admin Including'
    base.extend(Variable)
    # base.set_admin_table_columns
    base.extend(Query)
    base.extend(Json)
    base.extend(Action)
    # base.set_custom_filters
    # base.set_actions
    # base.set_formdata
  end

  def self.login_field
    @login_field ||= :email
  end

  def self.use_rexy_admin_login
    @use_rexy_admin_login.nil? ? true : @use_rexy_admin_login
  end

  def self.use_rexy_admin_login= use
    @use_rexy_admin_login = use
  end
  
  mattr_accessor :auth_class
end
