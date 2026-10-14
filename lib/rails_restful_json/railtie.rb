module RailsRestfulJson
  class Railtie < Rails::Railtie
    # Jbuilder's scaffold views use these templates instead of its own, so
    # `rails g scaffold` adds actions. An app's lib/templates still wins.
    config.app_generators.templates << File.expand_path("templates", __dir__)

    # Match the HTML scaffold views, which don't show timestamps
    config.app_generators.jbuilder timestamps: false

    initializer "rails_restful_json.helper" do
      ActiveSupport.on_load(:action_view) do
        include RailsRestfulJson::Helper
      end
    end
  end
end
