json.item do
  json.partial! "items/item", item: @item
end
json.actions resource_actions(@item, context: :show)
