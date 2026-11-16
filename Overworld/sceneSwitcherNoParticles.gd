extends NinePatchRect 

@export_file("*.tscn") var target: String
@export var spawnPoint: String = ""

func _ready() -> void:
		$sceneSwitcher.target = target
		$sceneSwitcher.spawnPoint = spawnPoint
