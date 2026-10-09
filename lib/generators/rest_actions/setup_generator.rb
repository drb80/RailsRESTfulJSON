module RestActions
  class SetupGenerator < Rails::Generators::Base
    desc "Add resource_actions helper method to ApplicationHelper"

    def add_helper_method
      helper_file = "app/helpers/application_helper.rb"

      if !File.exist?(helper_file)
        create_file helper_file, helper_template
        say "  create  #{helper_file}"
        return
      end

      content = File.read(helper_file)

      if content.include?("def resource_actions")
        say "  skip    #{helper_file} (resource_actions already defined)"
        return
      end

      # Insert the method before the closing "end"
      new_content = content.gsub(/end\Z/, "#{helper_method_code}\nend")

      File.write(helper_file, new_content)
      say "  inject  #{helper_file}"
    end

    def done_message
      say "\n✓ RESTful JSON actions setup complete!"
      say "  • resource_actions helper is ready"
      say "  • Use: rails generate rest_actions:scaffold Post\n"
    end

    private

    def helper_template
      <<~RUBY
        module ApplicationHelper
        #{helper_method_code}
        end
      RUBY
    end

    def helper_method_code
      <<~RUBY

        def resource_actions(resource, context: nil)
          case context
          when :show
            show_actions(resource)
          when :index
            index_actions(resource)
          else
            []
          end
        end

        private

        def show_actions(resource)
          resource_name = resource.class.name.underscore
          [
            { name: "edit", url: send("edit_#{resource_name}_path", resource), method: "GET" },
            { name: "update", url: send("#{resource_name}_path", resource), method: "PATCH" },
            { name: "destroy", url: send("#{resource_name}_path", resource), method: "DELETE" },
            { name: "list", url: send("#{resource_name.pluralize}_path"), method: "GET" }
          ]
        end

        def index_actions(resource)
          resource_name = resource.class.name.underscore.pluralize
          [
            { name: "create", url: send("#{resource_name}_path"), method: "POST" },
            { name: "new", url: send("new_#{resource_name.singularize}_path"), method: "GET" }
          ]
        end
      RUBY
    end
  end
end
