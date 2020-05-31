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
    # base.set_create_params_checker
    # base.set_create_action
    # base.set_update_params_checker
    # base.set_update_action
    # base.set_auth_orm_query
    # base.set_auth_sql_query
  end

  def auth_orm_query
    @auth_orm_query ||= {}
  end

  def auth_sql_query
    @auth_sql_query ||= ''
  end

  def self.login_field
    @login_field ||= :email
  end

  mattr_accessor :auth_class
  mattr_reader :auth_orm_query, :auth_sql_query
end
