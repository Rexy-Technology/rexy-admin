# frozen_string_literal: true

desc 'Create'
namespace :rexy_admin do
  task migrate: [:environment] do
    Rake::Task['db:migrate'].invoke
  end
  task seed: [:environment] do
    RexyAdminAuth.create(email: 'superadmin', password: '$~!e~Ys2jb') if RexyAdminAuth.count.zero?
  end
end
