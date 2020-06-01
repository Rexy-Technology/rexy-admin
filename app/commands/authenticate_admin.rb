# frozen_string_literal: true

class AuthenticateAdmin
  prepend SimpleCommand

  def initialize(opts = {})
    @opts = opts
  end

  def call
    if admin.present? && valid_password
      { token: JsonWebToken.encode(admin_id: admin.id.to_s) }
    else
      errors.add(:error_message, 'Incorrect email or password provided!')
      errors.add(:error_code, 0)
      nil
    end
  end

  private

  def valid_password
    admin.authenticate(opts[:password])
  end

  def admin
    @admin ||= RexyAdmin.auth_class.find_by(RexyAdmin.login_field => opts[:email])
  end

  attr_reader :opts
end
