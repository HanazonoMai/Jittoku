@tool
extends CharacterBody2D

@export var timeline : DialogicTimeline
@export var npcName : String
@export var sprite : Texture2D

func _ready():
	$Sprite2D.texture = sprite

func interact() -> void:
	if Dialogic.current_timeline == null:
		run_dialogue(timeline)

func run_dialogue(dialogueName):
	Dialogic.start(dialogueName)
	#chatOk = false
