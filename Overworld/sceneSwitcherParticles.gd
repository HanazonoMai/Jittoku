@tool
extends NinePatchRect

enum DIRECTION { Left, Right, Top, Bottom }

@export var towards : DIRECTION = DIRECTION.Right
@export var textures : Array[Texture]

@export_file("*.tscn") var target: String
@export var spawnPoint: String = ""

func _ready() -> void:
	matchVisual()
	if not Engine.is_editor_hint():
		$sceneSwitcher.target = target
		$sceneSwitcher.spawnPoint = spawnPoint

func _process(_delta):
	if Engine.is_editor_hint():
		matchVisual()

func matchVisual():
	texture = textures[towards]
