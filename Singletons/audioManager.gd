extends AudioStreamPlayer

var fadeTime = 2
var targetVolume = 0.0

func _ready():
	volume_db = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func playMusic(_stream: AudioStream, fadeIn:bool = false, fadeOutPrev: bool = false):
	stream = _stream
	if not stream:
		push_error("MusicManager: Failed to load ")
		return
	
	if playing:
		stopMusic(fadeOutPrev)
		

	play()
	if fadeIn:
		musicFadeIn()
	
func stopMusic(fadeOut: bool = false):
	if fadeOut:
		musicFadeOut()
		await get_tree().create_timer(fadeTime).timeout
	stop()

func musicFadeIn():
	var tween = create_tween()
	tween.tween_property(self, "volume_db", targetVolume, fadeTime)
	
func musicFadeOut():
	var tween = create_tween()
	tween.tween_property(self, "volume_db", -80, fadeTime)
	
func playSFX(path: String):
	var sfx = load(path)

	var p = AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = sfx
	add_child(p)
	p.play()

	p.finished.connect(p.queue_free) # auto-clean when done
