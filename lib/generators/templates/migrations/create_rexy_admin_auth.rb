# frozen_string_literal: true

class CreateRexyAdminAuth < ActiveRecord::Migration[6.0]
  def change
    create_table(:rexy_admin_auths) do |t|
      t.string :email, null: false, default: ''
      t.string :password_digest, null: false, default: ''

      t.timestamps
    end
  end
end
