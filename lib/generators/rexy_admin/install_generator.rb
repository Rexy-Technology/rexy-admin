require 'securerandom'
require 'rails/generators'
require 'rails/generators/migration'

# rubocop:disable ClassLength, MethodLength, ExpandPathArguments
module RexyAdmin
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../../templates', __FILE__)

    desc 'Creates a Config file and copy locale files to your application.'
    class_option :orm

    def copy_migration
      migration_template \
        'migrations/create_rexy_admin_auth.rb',
        'db/migrate/create_rexy_admin_auth.rb'
      rake('rexy_admin:migrate')
    end

    def copy_model
      template 'models/rexy_admin_auth.rb', 'app/models/rexy_admin_auth.rb'
      rake('rexy_admin:seed')
    end


    def copy_errors
      copy_file 'public/404.html', 'public/404.html'
      copy_file 'public/422.html', 'public/422.html'
      copy_file 'public/500.html', 'public/500.html'
    end

    def self.next_migration_number(dir)
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end
  end
end
# rubocop:enable all
