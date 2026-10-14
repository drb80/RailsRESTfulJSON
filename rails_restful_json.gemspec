require_relative "lib/rails_restful_json/version"

Gem::Specification.new do |s|
  s.name        = "rails_restful_json"
  s.version     = RailsRestfulJson::VERSION
  s.summary     = "Include available actions in Rails JSON responses"
  s.description = "A view helper and generators that add HATEOAS-style action metadata (name, url, method) to Jbuilder responses."
  s.authors     = ["drb80"]
  s.homepage    = "https://github.com/drb80/RailsRESTfulJSON"
  s.license     = "MIT"
  s.files       = Dir["lib/**/*.{rb,tt}", "README.markdown", "LICENSE"]
  s.required_ruby_version = ">= 3.1"
  s.add_dependency "railties", ">= 7.0"
end
