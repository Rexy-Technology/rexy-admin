# frozen_string_literal: true

class RexyAdminAuth < ActiveRecord::Base
  has_secure_password
end
