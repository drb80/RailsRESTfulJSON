# Rails RESTful JSON

A Rails REST API that includes available actions in JSON responses, following HATEOAS principles. Each response includes explicit HTTP methods and relative paths for available operations.

## Overview

This project demonstrates a pattern for making JSON APIs more self-documenting by including action metadata in responses. Clients can discover what operations are available on a resource without hardcoding URL patterns or HTTP methods.

The JSON responses offer the same links as Rails' HTML scaffold views, so they're familiar to Rails developers and a front-end framework can use them directly.

## Features

- **Collection actions** (index): a "new" action, plus a "show" action for each item
- **Resource actions** (show): "edit", "index", and "destroy" actions
- **Explicit HTTP methods**: Each action includes the HTTP verb needed
- **Relative paths**: All URLs use relative paths for portability
- **Reusable helper**: Generic pattern works across any resource
- **Works with `rails g scaffold`**: New scaffolds get JSON views with actions, no extra generator needed
- **No timestamps by default**: Like the HTML scaffold views, the JSON leaves out `created_at` and `updated_at`
- **Retrofit generator**: Add actions to existing resources

## Setup

Add the gem to your app's `Gemfile`:

```ruby
gem "rails_restful_json", github: "drb80/RailsRESTfulJSON"
```

Then run `bundle install`. That's it! The `resource_actions` helper is available in all views, and `rails generate scaffold` creates JSON views with actions. To pick up later fixes, run `bundle update rails_restful_json`.

### Customizing the helper

To change the default actions for your whole app, copy the helper into `app/helpers/application_helper.rb`:

```bash
rails generate rest_actions:setup
```

Your copy overrides the gem's version, so edit it freely. (You can also define `resource_actions` yourself and call `super` to extend the gem's actions.)

### Customizing the templates

To change what scaffolds generate, copy the gem's templates into your app and edit them. Your copies take precedence:

```bash
mkdir -p lib/templates/rails/jbuilder
cp "$(bundle info --path rails_restful_json)"/lib/rails_restful_json/templates/rails/jbuilder/*.tt lib/templates/rails/jbuilder/
```

To include timestamps in the JSON again, add this to `config/application.rb`:

```ruby
config.generators.jbuilder timestamps: true
```

### Without the gem

You can also copy the generators and templates straight into your app instead:

```bash
cp -r lib/generators/rest_actions your-rails-app/lib/generators/
mkdir -p your-rails-app/lib/templates
cp -r lib/rails_restful_json/templates/rails your-rails-app/lib/templates/
rails generate rest_actions:setup
```

In this case the setup step is required, since it's what adds `resource_actions` to your app. To leave timestamps out of the JSON, add `config.generators.jbuilder timestamps: false` to `config/application.rb`.

Rails 7.1+ apps autoload `lib/`, so tell Zeitwerk to skip these files in `config/application.rb`, or production will fail to boot when it eager loads them:

```ruby
config.autoload_lib(ignore: %w[assets tasks generators rails_restful_json])
```

## Generators

### Create a new resource with JSON actions

Use the standard Rails scaffold generator:

```bash
rails generate scaffold Post title:string body:text
```

The gem replaces Jbuilder's `index.json.jbuilder` and `show.json.jbuilder` templates, so the scaffold's JSON views include actions. The same applies to `rails generate scaffold_controller`.

### Add JSON actions to existing resources

```bash
rails generate rest_actions:install_json Post Comment User
```

For each resource, this:
- Creates `index.json.jbuilder` and `show.json.jbuilder` with actions if they're missing
- Replaces them if they're unchanged from what Rails' scaffold (or an earlier version of this gem) generated
- Skips views that already have actions, and warns about views you've customized so you can add actions by hand
- Creates a `_resource.json.jbuilder` partial with the model's columns if it's missing (existing partials are left alone)

## Example Responses

### Index (`GET /items.json`)

```json
{
  "items": [
    {
      "id": 1,
      "what": "Kitty Litter",
      "due": "2026-10-14",
      "url": "http://localhost:3000/items/1.json",
      "actions": [
        { "name": "show", "url": "/items/1", "method": "GET" }
      ]
    }
  ],
  "actions": [
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
    "due": "2026-10-14",
    "url": "http://localhost:3000/items/1.json"
  },
  "actions": [
    { "name": "edit", "url": "/items/1/edit", "method": "GET" },
    { "name": "index", "url": "/items", "method": "GET" },
    { "name": "destroy", "url": "/items/1", "method": "DELETE" }
  ]
}
```

## Implementation

### Helper Method

The `resource_actions` helper (provided by the gem, or copied into `ApplicationHelper` by `rest_actions:setup`) generates action metadata based on resource type and context:

```ruby
resource_actions(@item, context: :show)        # Returns show/item actions
resource_actions(Item.new, context: :index)    # Returns index/collection actions
resource_actions(item, context: :index_item)   # Returns actions for each item in the index
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

**`index.json.jbuilder`**: Wraps the items array, adds actions to each item, and includes index actions
```jbuilder
json.items do
  json.array! @items do |item|
    json.partial! "items/item", item: item
    json.actions resource_actions(item, context: :index_item)
  end
end
json.actions resource_actions(Item.new, context: :index)
```

## Adding to Other Resources

`rest_actions:install_json` handles this for you. To add the pattern by hand to another resource (e.g., Posts):

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
  json.array! @posts do |post|
    json.partial! "posts/post", post: post
    json.actions resource_actions(post, context: :index_item)
  end
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
- **Same links as the HTML views**: Each response has the actions the matching HTML scaffold page links to ("Back to items" becomes "index"), and action names match Rails' controller actions
- **Generic helper**: The base helper uses Rails conventions to work across resources with zero configuration
- **Wrapped responses**: Index uses `items` key (not top-level array) for consistency with show's `item` key
