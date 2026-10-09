json.items do
  json.array! @items, partial: "items/item", as: :item
end
json.actions resource_actions(Item.new, context: :index)
