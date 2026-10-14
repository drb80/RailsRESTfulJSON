module RestActions
  class InstallJsonGenerator < Rails::Generators::Base
    argument :resources, type: :array, default: [], banner: "resource resource"

    desc "Add JSON actions pattern to existing resources"

    # Use the same index/show templates as `rails g scaffold`, including any
    # overrides in the app's lib/templates/rails/jbuilder
    def self.source_paths
      Rails::Generators.templates_path.map { |path| File.join(path, "rails", "jbuilder") }
    end

    def check_resources
      if resources.empty?
        say "Usage: rails generate rest_actions:install_json Post Comment User"
        say "\nThis will add index.json.jbuilder and show.json.jbuilder with actions to each resource."
      end
    end

    def install_json_views
      resources.each do |resource|
        @singular_table_name = resource.underscore.singularize
        @plural_table_name = @singular_table_name.pluralize
        @class_name = @singular_table_name.camelize

        install_view "index"
        install_view "show"
        install_partial
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

    attr_reader :singular_table_name, :plural_table_name, :class_name

    def partial_path_name
      "#{plural_table_name}/#{singular_table_name}"
    end

    def install_view(view)
      path = "app/views/#{plural_table_name}/#{view}.json.jbuilder"

      content = File.exist?(path) && File.read(path)

      if !content
        template "#{view}.json.jbuilder", path
      elsif replaceable?(view, content)
        template "#{view}.json.jbuilder", path, force: true
      elsif content.include?("resource_actions")
        say_status :skip, "#{path} (already has actions)", :blue
      else
        say_status :skip, "#{path} (customized; add actions by hand)", :yellow
      end
    end

    # Views still matching what Rails' scaffold or an earlier version of this
    # gem generated, which are safe to overwrite
    def replaceable?(view, content)
      known = {
        "index" => [
          %(json.array! @#{plural_table_name}, partial: "#{partial_path_name}", as: :#{singular_table_name}),
          <<~JBUILDER
            json.#{plural_table_name} do
              json.array! @#{plural_table_name}, partial: "#{partial_path_name}", as: :#{singular_table_name}
            end
            json.actions resource_actions(#{class_name}.new, context: :index)
          JBUILDER
        ],
        "show" => [
          %(json.partial! "#{partial_path_name}", #{singular_table_name}: @#{singular_table_name})
        ]
      }
      known.fetch(view).map(&:strip).include?(content.strip)
    end

    def install_partial
      path = "app/views/#{plural_table_name}/_#{singular_table_name}.json.jbuilder"

      if File.exist?(path)
        say_status :skip, "#{path} (already exists)", :blue
        return
      end

      fields = partial_fields.map { |field| ":#{field}" }.join(", ")
      create_file path, <<~JBUILDER
        json.extract! #{singular_table_name}, #{fields}
        json.url #{singular_table_name}_url(#{singular_table_name}, format: :json)
      JBUILDER
    end

    # The model's columns without timestamps, matching the HTML scaffold views.
    # Falls back to just id if the model or its table isn't available yet.
    def partial_fields
      columns = begin
        class_name.safe_constantize.try(:column_names)
      rescue StandardError # e.g. the table hasn't been migrated yet
        nil
      end

      if columns.blank?
        say_status :warning, "couldn't read columns for #{class_name}; add its fields to the partial by hand", :yellow
        return %w[id]
      end

      columns - %w[created_at updated_at]
    end
  end
end
