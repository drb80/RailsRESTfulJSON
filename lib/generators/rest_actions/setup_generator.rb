module RestActions
  class SetupGenerator < Rails::Generators::Base
    desc "Copy the resource_actions helper into ApplicationHelper (optional with the gem; needed if you copied the generators in by hand)"

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
      say "\n✓ resource_actions copied into ApplicationHelper"
      say "  • Edit it there to customize actions for your app"
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
      <<~'RUBY'.indent(2)

        def resource_actions(resource, context: nil)
          case context
          when :show
            show_actions(resource)
          when :index
            index_actions(resource)
          when :index_item
            index_item_actions(resource)
          else
            []
          end
        end

        private

        def show_actions(resource)
          resource_name = resource.class.name.underscore
          [
            { name: "edit", url: send("edit_#{resource_name}_path", resource), method: "GET" },
            { name: "index", url: send("#{resource_name.pluralize}_path"), method: "GET" },
            { name: "destroy", url: send("#{resource_name}_path", resource), method: "DELETE" }
          ]
        end

        def index_item_actions(resource)
          resource_name = resource.class.name.underscore
          [
            { name: "show", url: send("#{resource_name}_path", resource), method: "GET" }
          ]
        end

        def index_actions(resource)
          resource_name = resource.class.name.underscore.pluralize
          [
            { name: "new", url: send("new_#{resource_name.singularize}_path"), method: "GET" }
          ]
        end
      RUBY
    end
  end
end
