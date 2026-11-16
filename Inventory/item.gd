extends Resource
class_name Item

enum Type {Use, Equip, KeyItem}

@export var name: String
@export var icon: Texture2D
@export var type: Type = Type.Use
#@export var pluralName: String
@export_multiline var description: String

@export var maxStacks : int = 99
#var amount: int = 0

#@export var sellable : SellData 
#@export var equipable: EquipData
#@export var skill : Skills

#func serialize() -> Dictionary:
#	return {"resource_path": resource_path, "amount": amount}

#static func deserialize(data: Dictionary) -> Item:
#	var item = load(data["resource_path"])
#	if not item is Item:
#		return null
#	for property: String in data:
#		if property != "resource_path":
#			item.set(property, data[property])
#	return item
