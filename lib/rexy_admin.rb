require 'rexy_admin/engine'
require 'rexy_admin/variable'
require 'rexy_admin/query'
require 'rexy_admin/json'
require 'rexy_admin/action'



module RexyAdmin
  def self.included(base)
    puts '------>Rexy Admin Including'
    base.extend(Variable)
    base.set_admin_table_columns
    base.extend(Query)
    base.extend(Json)
    base.extend(Action)
    # base.set_custom_filters
    # base.set_actions
    # base.set_formdata
    base.set_create_params_checker
    base.set_create_action
    base.set_update_params_checker
    base.set_update_action
  end

  # def table_actions
  #   self.class.get_actions.inject([]) do |current, v|
  #     if %i[activate edit remove].include?(v)
  #       case v
  #       when :activate
  #         current << toggle_action
  #       when :edit
  #         current << edit_action
  #       when :remove
  #         current << remove_action
  #       end
  #     elsif self.class.reflect_on_association(v.to_sym).macro == :has_many
  #       current << { label: v.to_s.camelize,
  #                    method: 'get',
  #                    url: "#{self.class.table_name}/#{id}/#{v}" }
  #     else
  #       next current
  #     end
  #   end
  # end
  mattr_accessor :auth_class
end
