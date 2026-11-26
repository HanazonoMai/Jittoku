extends NinePatchRect


@export_file("*.dtl") var dialogueName := ""
@export var cutsceneID := ""
@export var pauseGame := true

var room : Node

signal finished

func _ready():
	room = get_parent()


func start():
	if dialogueName == "" or cutsceneID == "":
		return
	if KeyManager.hasCutscenePlayed(cutsceneID):
		return
	print("Starting scene ", cutsceneID)
	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
	if pauseGame:
		get_tree().paused = true
	#room.set_process(false)
	Dialogic.timeline_ended.connect(_timelineEnded)
	var cutscene = Dialogic.start(dialogueName)
	cutscene.process_mode = Node.PROCESS_MODE_ALWAYS
	KeyManager.setCutscene(cutsceneID)
	

func _timelineEnded():
	Dialogic.timeline_ended.disconnect(_timelineEnded)
	get_tree().paused = false
	finished.emit()
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not (body is PlayerOverworld):
		return
	start()
