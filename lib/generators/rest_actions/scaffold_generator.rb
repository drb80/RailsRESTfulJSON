require 'rails/generators/model_helpers'

module RestActions
  class ScaffoldGenerator < Rails::Generators::Base
    include Rails::Generators::ModelHelpers

    argument :name, type: :string
    argument :attributes, type: :array, default: [], banner: "field:type field:type"

    desc "Generate a RESTful scaffold with JSON actions pattern"

    def create_model
      generate "model", "#{name} #{attributes.join(' ')}"
    end

    def create_controller
      generate "scaffold_controller", name
    end

    def create_views
      generate "scaffold", name
    end

    def create_json_templates
      empty_directory "app/views/#{plural_name}"
      create_file "app/views/#{plural_name}/index.json.jbuilder", index_template
      create_file "app/views/#{plural_name}/show.json.jbuilder", show_template
      create_file "app/views/#{plural_name}/_#{singular_name}.json.jbuilder", item_template
    end

    def create_routes
      route "resources :#{plural_name}"
    end

    def done_message
      say "\n✓ RESTful JSON scaffold '#{name}' generated!"
      say "  • Model: #{class_name}"
      say "  • Controller: #{class_name.pluralize}Controller"
      say "  • Views with HTML and JSON responses"
      say "  • JSON responses include available actions\n"
      say "Next steps:"
      say "  rails db:migrate"
      say "  rails server"
    end

    private

    def singular_name
      name.underscore
    end

    def plural_name
      name.underscore.pluralize
    end

    def class_name
      name.camelize
    end

    def index_template
      <<~JBUILDER
        json.#{plural_name} do
          json.array! @#{plural_name}, partial: "#{plural_name}/#{singular_name}", as: :#{singular_name}
        end
        json.actions resource_actions(#{class_name}.new, context: :index)
      JBUILDER
    end

    def show_template
      <<~JBUILDER
        json.#{singular_name} do
          json.partial! "#{plural_name}/#{singular_name}", #{singular_name}: @#{singular_name}
        end
        json.actions resource_actions(@#{singular_name}, context: :show)
      JBUILDER
    end

    def item_template
      <<~JBUILDER
        json.extract! #{singular_name}, :id, :created_at, :updated_at
        json.url #{singular_name}_url(#{singular_name}, format: :json)
      JBUILDER
    end
  end
end
