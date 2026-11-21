extends NinePatchRect


@export_file("*.dtl") var dialogueName := ""
@export var cutsceneID := ""



func start():
	print("Starting scene")
	if dialogueName == "" or cutsceneID == "":
		return
	if KeyManager.hasCutscenePlayed(cutsceneID):
		return
	Dialogic.start(dialogueName)
	KeyManager.setCutscene(cutsceneID)
	


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not (body is PlayerOverworld):
		return
	start()
