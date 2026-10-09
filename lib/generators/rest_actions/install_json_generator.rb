module RestActions
  class InstallJsonGenerator < Rails::Generators::Base
    argument :resources, type: :array, default: [], banner: "resource resource"

    desc "Add JSON actions pattern to existing resources"

    def check_resources
      if resources.empty?
        say "Usage: rails generate rest_actions:install_json Post Comment User"
        say "\nThis will add index.json.jbuilder and show.json.jbuilder with actions to each resource."
      end
    end

    def install_json_views
      resources.each do |resource|
        resource_name = resource.underscore
        plural_name = resource_name.pluralize
        singular_name = resource_name

        index_path = "app/views/#{plural_name}/index.json.jbuilder"
        show_path = "app/views/#{plural_name}/show.json.jbuilder"
        partial_path = "app/views/#{plural_name}/_#{singular_name}.json.jbuilder"

        unless File.exist?(index_path)
          create_file index_path, index_template(resource, plural_name, singular_name)
          say "  create  #{index_path}"
        else
          say "  skip    #{index_path} (already exists)"
        end

        unless File.exist?(show_path)
          create_file show_path, show_template(resource, plural_name, singular_name)
          say "  create  #{show_path}"
        else
          say "  skip    #{show_path} (already exists)"
        end

        unless File.exist?(partial_path)
          create_file partial_path, partial_template(singular_name)
          say "  create  #{partial_path}"
        else
          say "  skip    #{partial_path} (already exists)"
        end
      end
    end

    def done_message
      if resources.any?
        say "\n✓ JSON actions pattern installed for #{resources.join(', ')}"
        say "  • JSON endpoints now include available actions"
        say "  • Customize actions by modifying the templates in app/views/*/\n"
      end
    end

    private

    def index_template(resource, plural_name, singular_name)
      <<~JBUILDER
        json.#{plural_name} do
          json.array! @#{plural_name}, partial: "#{plural_name}/#{singular_name}", as: :#{singular_name}
        end
        json.actions resource_actions(#{resource}.new, context: :index)
      JBUILDER
    end

    def show_template(resource, plural_name, singular_name)
      <<~JBUILDER
        json.#{singular_name} do
          json.partial! "#{plural_name}/#{singular_name}", #{singular_name}: @#{singular_name}
        end
        json.actions resource_actions(@#{singular_name}, context: :show)
      JBUILDER
    end

    def partial_template(singular_name)
      <<~JBUILDER
        json.extract! #{singular_name}, :id, :created_at, :updated_at
        json.url #{singular_name}_url(#{singular_name}, format: :json)
      JBUILDER
    end
  end
end
