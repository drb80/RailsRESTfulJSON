module RailsRestfulJson
  module Helper
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
  end
end
