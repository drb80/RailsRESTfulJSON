# Rails RESTful JSON

A Rails REST API that includes available actions in JSON responses, following HATEOAS principles. Each response includes explicit HTTP methods and relative paths for available operations.

## Overview

This project demonstrates a pattern for making JSON APIs more self-documenting by including action metadata in responses. Clients can discover what operations are available on a resource without hardcoding URL patterns or HTTP methods.

## Features

- **Collection actions** (index): Show "create" and "new" actions
- **Resource actions** (show): Show "edit", "update", "destroy", and "list" actions
- **Explicit HTTP methods**: Each action includes the HTTP verb needed
- **Relative paths**: All URLs use relative paths for portability
- **Reusable helper**: Generic pattern works across any resource
- **Generators**: Scaffold new resources or retrofit existing ones with the pattern

## Setup

### 1. Copy generators to your Rails app

```bash
cp -r lib/generators/rest_actions your-rails-app/lib/generators/
```

### 2. Run the setup generator

```bash
rails generate rest_actions:setup
```

This automatically adds the `resource_actions` helper method to your `app/helpers/application_helper.rb`.

That's it! You're ready to scaffold new resources with JSON actions built in.

## Generators

### Create a new resource with JSON actions

```bash
rails generate rest_actions:scaffold Post title:string body:text
```

This creates:
- Model, controller, and all standard Rails views
- JSON templates (`index.json.jbuilder`, `show.json.jbuilder`) with actions built in
- Routes
- Tests

### Add JSON actions to existing resources

```bash
rails generate rest_actions:install_json Post Comment User
```

This adds the JSON templates to one or more existing resources:
- Creates `index.json.jbuilder` with collection actions
- Creates `show.json.jbuilder` with resource actions
- Creates `_resource.json.jbuilder` partial
- Skips existing templates (won't overwrite)

### Use with standard Rails generators

You can also use the standard Rails controller generator and add JSON actions afterward:

```bash
# Generate a controller with views
rails generate controller Products index show new

# Add JSON templates with actions
rails generate rest_actions:install_json Products

# Add the resource route manually
# In config/routes.rb:
# resources :products
```

## Example Responses

### Index (`GET /items.json`)

```json
{
  "items": [
    {
      "id": 1,
      "what": "Kitty Litter",
      "when": "2026-10-09",
      "created_at": "2026-10-09T18:12:36.640Z",
      "updated_at": "2026-10-09T18:12:36.640Z",
      "url": "http://localhost:3000/items/1.json"
    }
  ],
  "actions": [
    { "name": "create", "url": "/items", "method": "POST" },
    { "name": "new", "url": "/items/new", "method": "GET" }
  ]
}
```

### Show (`GET /items/1.json`)

```json
{
  "item": {
    "id": 1,
    "what": "Kitty Litter",
    "when": "2026-10-09",
    "created_at": "2026-10-09T18:12:36.640Z",
    "updated_at": "2026-10-09T18:12:36.640Z",
    "url": "http://localhost:3000/items/1.json"
  },
  "actions": [
    { "name": "edit", "url": "/items/1/edit", "method": "GET" },
    { "name": "update", "url": "/items/1", "method": "PATCH" },
    { "name": "destroy", "url": "/items/1", "method": "DELETE" },
    { "name": "list", "url": "/items", "method": "GET" }
  ]
}
```

## Implementation

### Helper Method

The `ApplicationHelper#resource_actions` method generates action metadata based on resource type and context:

```ruby
resource_actions(@item, context: :show)   # Returns show/item actions
resource_actions(Item.new, context: :index)  # Returns index/collection actions
```

The helper automatically:
- Derives the resource name from the class
- Builds correct route helpers using Rails conventions
- Returns arrays of `{ name, url, method }` hashes

### Jbuilder Templates

**`show.json.jbuilder`**: Wraps the item partial and includes show actions
```jbuilder
json.item do
  json.partial! "items/item", item: @item
end
json.actions resource_actions(@item, context: :show)
```

**`index.json.jbuilder`**: Wraps the items array and includes index actions
```jbuilder
json.items do
  json.array! @items, partial: "items/item", as: :item
end
json.actions resource_actions(Item.new, context: :index)
```

## Adding to Other Resources

To add this pattern to another resource (e.g., Posts):

1. Update `show.json.jbuilder`:
```jbuilder
json.post do
  json.partial! "posts/post", post: @post
end
json.actions resource_actions(@post, context: :show)
```

2. Update `index.json.jbuilder`:
```jbuilder
json.posts do
  json.array! @posts, partial: "posts/post", as: :post
end
json.actions resource_actions(Post.new, context: :index)
```

## Customizing Actions

To customize actions for a specific resource, create a resource-specific helper:

```ruby
# app/helpers/items_helper.rb
module ItemsHelper
  def item_show_actions(item)
    [
      { name: "edit", url: edit_item_path(item), method: "GET" },
      { name: "duplicate", url: item_path(item, action: "duplicate"), method: "POST" },
      { name: "delete", url: item_path(item), method: "DELETE" },
      { name: "back", url: items_path, method: "GET" }
    ]
  end
end
```

Then in your template:
```jbuilder
json.actions item_show_actions(@item)
```

## Design Decisions

- **Relative paths**: Allow easy deployment across different domains/subpaths
- **Explicit methods**: Clients always know which HTTP verb to use (no guessing)
- **Generic helper**: The base helper uses Rails conventions to work across resources with zero configuration
- **Wrapped responses**: Index uses `items` key (not top-level array) for consistency with show's `item` key
