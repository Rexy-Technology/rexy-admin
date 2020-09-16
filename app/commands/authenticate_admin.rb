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
      errors.add(:errors,  {
        "message": "Incorrect email or password provided!",
        "details": {
          error_code: 0
        }
      })
    end
  end

  private

  def valid_password
    admin.authenticate(opts[:password])
  end

  def admin
    @admin ||= RexyAdmin.auth_model.find_by(RexyAdmin.login_field => opts[RexyAdmin.login_field])
  end

  attr_reader :opts
end
