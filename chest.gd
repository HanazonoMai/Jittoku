extends StaticBody2D

@export var chestID: String = ""
@export var gold : int = 0
@export var item: Item
@export var quantity: int = 1

@onready var sprite = $Sprite2D
var inRange = false 

func _ready() -> void:
	update_sprite()


#func _unhandled_input(event: InputEvent) -> void:
#	if inRange and event.is_action_pressed("accept") and !KeyManager.isChestOpen(chestID):
#		get_viewport().set_input_as_handled()
#		open_chest()

func open_chest() -> void:
	KeyManager.setChestOpen(chestID)
	update_sprite()

	if gold > 0:
		PlayerData.gold += gold
		#PopUp.showMsg("Found " + str(gold) + " gold")
	#elif item:
		#pass
		#PlayerData.inventory.addItem(item, quantity)
		#PopUp.showMsg("Found " + item.name + "x" + str(quantity))

func update_sprite() -> void:
	sprite.frame = 1 if KeyManager.isChestOpen(chestID) else 0
	

func interact() -> void:
	if KeyManager.isChestOpen(chestID):
		return
		
	open_chest()

#func _on_area_2d_body_entered(body: Node2D) -> void:
#	if body.is_in_group("player"):
#		inRange = true

#func _on_area_2d_body_exited(body: Node2D) -> void:
#	if body.is_in_group("player"):
#		inRange = false
