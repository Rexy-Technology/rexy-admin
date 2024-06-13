$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "rexy_admin/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "rexy_admin"
  spec.version     = RexyAdmin::VERSION
  spec.authors     = ["rex huynh"]
  spec.email       = ["huynhvu1909@gmail.com"]
  # spec.homepage    = "TODO"
  spec.summary     = "RexyAdmin."
  spec.description = "Description of RexyAdmin."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 7.0.4"
end
