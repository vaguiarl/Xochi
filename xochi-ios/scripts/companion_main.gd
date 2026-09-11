extends Node2D
## A complete Spanish-guided encounter. Language chooses a goal; real physics
## carries it out. The music and learning evidence survive every quick retry.
const CREAM := Color("fff0d1")
const GOLD := Color("efc580")
const INK := Color("103e46")
const PINK := Color("f5b5ba")
const LESSONS := [
	{"phrase":"Ven.", "meaning":"Come.", "intent":"come", "choices":["come","wait"], "target":Vector2(260,555), "spawn":Vector2(130,555), "jump":false, "title":"A new friend", "title_es":"Una nueva amiga", "story":"Xochi looks back. What is she being asked to do?", "story_es":"Xochi mira hacia ti. ¿Qué le están pidiendo?"},
	{"phrase":"Espera.", "meaning":"Wait.", "intent":"wait", "choices":["come","wait"], "target":Vector2(260,555), "spawn":Vector2(260,555), "jump":false, "title":"A moment together", "title_es":"Un momento juntas", "story":"Calabrija studies the lanterns. What does this word ask?", "story_es":"Calabrija mira los faroles. ¿Qué pide esta palabra?"},
	{"phrase":"Ven.", "meaning":"Come.", "intent":"come", "choices":["wait","come"], "target":Vector2(450,555), "spawn":Vector2(260,555), "jump":false, "title":"Follow the lantern", "title_es":"Sigue el farol", "story":"You have heard this word before. Use it by the water.", "story_es":"Ya escuchaste esta palabra. Úsala junto al agua."},
	{"phrase":"Al bote.", "meaning":"Onto the boat.", "intent":"boat", "choices":["bridge","boat"], "target":Vector2(640,505), "spawn":Vector2(450,555), "jump":true, "title":"Two ways across", "title_es":"Dos caminos", "story":"The crow guards the bridge. Which route did you hear?", "story_es":"El cuervo vigila el puente. ¿Qué camino escuchaste?"},
	{"phrase":"Espera.", "meaning":"Wait.", "intent":"wait", "choices":["jump","wait"], "target":Vector2(640,505), "spawn":Vector2(640,505), "jump":false, "title":"Watch his eyes", "title_es":"Mira sus ojos", "story":"The guard turns his head. What should Xochi do?", "story_es":"El guardia gira la cabeza. ¿Qué debe hacer Xochi?"},
	{"phrase":"Ahora, salta.", "meaning":"Now, jump.", "intent":"jump", "choices":["wait","jump"], "target":Vector2(890,555), "spawn":Vector2(640,505), "jump":true, "title":"Your moment", "title_es":"Tu momento", "story":"Calabrija catches his eye. Give Xochi a plan.", "story_es":"Calabrija llama su atención. Dale un plan a Xochi."},
	{"phrase":"Espera.", "meaning":"Wait.", "intent":"wait", "choices":["come","wait"], "target":Vector2(890,555), "spawn":Vector2(890,555), "jump":false, "title":"No friend left behind", "title_es":"Que nadie se quede atrás", "story":"You know this word. Let the little one catch up.", "story_es":"Ya conoces esta palabra. Deja que te alcance la pequeña."},
	{"phrase":"Al puente.", "meaning":"To the bridge.", "intent":"bridge", "choices":["boat","bridge"], "target":Vector2(1080,555), "spawn":Vector2(890,555), "jump":false, "title":"La fiesta de las voces", "title_es":"La fiesta de las voces", "story":"Everyone is waiting at the bridge. Bring them together.", "story_es":"Todos esperan en el puente. Reúnelos."}
]
var save = preload("res://scripts/learning_progress.gd").new()
var locale := "en"
var voice_language := "es"
var world: Node2D
var player: CharacterBody2D
var controller: Node
var guard: Node2D
var calabrija: Node2D
var voice: Node
var scenery: Node2D
var ui: Control
var hud: Control
var modal: Control
var music: AudioStreamPlayer
var title_font: Font
var body_font: Font
var phrase_label: Label
var story_label: Label
var status_label: Label
var progress_label: Label
var mic_button: Button
var hear_button: Button
var choice_buttons: Array[Button] = []
var step := 0
var generation := 0
var playing := false
var finished := false
var retrying := false
var current_screen := "menu"
var pending_answer: Dictionary = {}
var hint_used := false
var waiting_time := 0.0
var elapsed := 0.0
var retry_count := 0
var retry_latencies: Array[float] = []
var session_uses: Dictionary = {}
var session_choices: Dictionary = {}
var session_spoken := 0
var status_text := ""
var status_left := 0.0
var listening_before := false
var friends_arrived := false
var _resize_pending := false
var curiosity_time := 0.0
var curiosity_seen := false
var example_duck_time := 0.0
var bridge_texture: Texture2D

func tr2(en: String, es: String) -> String:
	return es if locale == "es" else en

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	title_font = load("res://assets/title.ttf")
	body_font = load("res://assets/body.ttf")
	bridge_texture = load("res://assets/companion/bridge.png")
	save.read_save()
	locale = save.data.locale
	voice_language = save.data.voice_language
	var background := CanvasLayer.new()
	background.layer = -10
	add_child(background)
	scenery = load("res://scripts/scenery.gd").new()
	background.add_child(scenery)
	world = Node2D.new()
	world.name = "Encounter"
	world.z_index = -1
	add_child(world)
	_build_world()
	music = AudioStreamPlayer.new()
	music.name = "UninterruptedSong"
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	var track = load("res://assets/audio/music/music_menu.ogg")
	track.loop = true
	music.stream = track
	music.volume_db = -9 if save.data.music else -80
	add_child(music)
	music.play()
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.layer = 20
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	var router = load("res://scripts/ui_input.gd").new()
	router.main = self
	canvas.add_child(router)
	voice = load("res://scripts/companion_voice.gd").new()
	add_child(voice)
	voice.configure(voice_language)
	voice.intent_received.connect(_voice_intent)
	voice.status_changed.connect(_voice_status)
	get_viewport().size_changed.connect(_resize_ui)
	_layout_world()
	_show_menu()

func _build_world() -> void:
	for spec in [[0,555,500,false], [560,505,170,true], [790,555,490,false]]:
		var platform = load("res://scripts/platform.gd").new()
		platform.configure(Rect2(spec[0],spec[1],spec[2],20),spec[3])
		world.add_child(platform)
		if spec[0] == 790: platform.visible = false
	player = load("res://scripts/player.gd").new()
	player.name = "Xochi"
	player.z_index = 3
	player.character_texture = load("res://assets/xochi.png")
	player.character_atlas = load("res://assets/xochi-actions.png")
	world.add_child(player)
	player.reset_at(Vector2(130,555))
	player.active = false
	player.died.connect(_retry)
	controller = load("res://scripts/companion_controller.gd").new()
	add_child(controller)
	controller.configure(player)
	controller.manual_takeover.connect(_manual_takeover)
	controller.failed.connect(_guidance_failed)
	guard = load("res://scripts/crow_guard.gd").new()
	guard.z_index = 3
	world.add_child(guard)
	guard.configure(Vector2(985,416))
	guard.active = false
	calabrija = load("res://scripts/calabrija.gd").new()
	calabrija.z_index = 2
	world.add_child(calabrija)
	calabrija.position = Vector2(415,325)

func _layout_world() -> void:
	world.position.x = (get_viewport_rect().size.x - 1280) / 2
	guard.configure(world.to_global(Vector2(985,416)))
	guard.active = playing and not finished

func _process(delta: float) -> void:
	elapsed += delta
	example_duck_time = maxf(0.0,example_duck_time-delta)
	if playing and not finished:
		curiosity_time += delta
		if step == 0 and not curiosity_seen and curiosity_time > 2.0 and pending_answer.is_empty() and not controller.guiding and not player.has_manual_input() and not voice.listening and not voice.requesting:
			curiosity_seen = true
			controller.guide_to(world.to_global(Vector2(155,555)))
		if player.position.y > 750 or player.position.x < 25 or player.position.x > 1260:
			if not retrying: _retry()
		var listening_now: bool = voice.listening or voice.requesting
		if listening_now != listening_before:
			listening_before = listening_now
			# Listening preserves the available opening instead of spending it.
			guard.set_physics_process(not listening_now)
			if listening_now: _status(tr2("Listening in ","Escuchando en ")+("español" if voice_language=="es" else "English")+"…",20)
		if music:
			var level := -80.0 if not save.data.music else (-19.0 if listening_now or example_duck_time>0 else -9.0)
			music.volume_db = move_toward(music.volume_db,level,delta*18)
		if is_instance_valid(mic_button):
			mic_button.text = tr2("Stop mic","Parar voz") if listening_now else tr2("Speak","Hablar")
		if not pending_answer.is_empty() and not retrying:
			var lesson: Dictionary = LESSONS[step]
			if lesson.intent == "wait":
				if player.is_on_floor() and absf(player.velocity.x) < 12:
					waiting_time += delta
					if waiting_time >= 0.9: _complete_step()
				else: waiting_time = 0
			elif player.is_on_floor() and player.position.distance_to(lesson.target) < 24:
				_complete_step()
		if step == 5 and pending_answer.is_empty() and not listening_now and guard.state == "watch":
			# The opening returns indefinitely. Missing it never forces a restart.
			guard.distract("bell")
	if status_left > 0:
		status_left -= delta
		if status_left <= 0:
			status_text = ""
			_refresh_status()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(world): return
	var offset := world.position
	# The rendered capstone aligns with the right-bank collision surface at 555.
	if bridge_texture:
		draw_texture_rect(bridge_texture,Rect2(offset+Vector2(785,550.8),Vector2(500,190)),false)
	# Lanterns locate the two possible destinations without translating the cue.
	for pos in [Vector2(470,555),Vector2(1075,555)]:
		var p: Vector2 = pos + offset
		draw_line(p,p+Vector2(0,-115),Color("685a40"),4,true)
		draw_circle(p+Vector2(0,-112),20,Color(1,.72,.3,.11))
		draw_style_box(_style(GOLD,5),Rect2(p+Vector2(-8,-123),Vector2(16,23)))
	if playing and not finished and not pending_answer.is_empty():
		var target: Vector2 = LESSONS[step].target + offset
		draw_arc(target+Vector2(0,-7),28+sin(elapsed*4)*2,PI,TAU,32,GOLD,3,true)
	if player and player.character_texture:
		for i in 2:
			var p := Vector2(1120+i*47,555) if not friends_arrived else Vector2(1060+i*50,555)
			p += offset
			var h := 48.0 + sin(elapsed*2+i)*2
			draw_texture_rect(player.character_texture,Rect2(p+Vector2(-28,-h),Vector2(57,h)),false,Color("c4f0df") if i==0 else Color.WHITE)

func _new_context() -> void:
	generation += 1
	voice.stop()
	voice.begin_context("crossing-" + str(step),generation)
	listening_before = false
	example_duck_time = 0
	guard.set_physics_process(true)
	music.volume_db = -9 if save.data.music else -80

func _show_menu() -> void:
	get_tree().paused = false
	current_screen = "menu"
	playing = false
	finished = false
	retrying = false
	controller.cancel_guidance()
	player.clear_input()
	player.active = false
	guard.active = false
	_new_context()
	if is_instance_valid(hud): hud.hide()
	_make_modal()
	var size := get_viewport_rect().size
	var safe := _safe_rect()
	var left := maxf(80,safe.position.x+25)
	var column := VBoxContainer.new()
	column.position = Vector2(left,115)
	column.size = Vector2(650,460)
	column.add_theme_constant_override("separation",12)
	modal.add_child(column)
	column.add_child(_label(tr2("YOUR VOICE. HER ADVENTURE.","TU VOZ. SU AVENTURA."),20,GOLD))
	column.add_child(_label("Xochi",104,CREAM,true))
	column.add_child(_label("La fiesta de las voces",42,CREAM,true))
	var copy := _label(tr2("Learn Spanish by guiding a curious little friend.\nSpeak, listen, or take her by the hand.","Aprende español guiando a una pequeña amiga.\nHabla, escucha o llévala de la mano."),27)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(copy)
	var begin := _button(tr2("Meet Xochi","Conoce a Xochi"),_show_intro,true)
	begin.name = "Begin"
	column.add_child(begin)
	var small := _label(tr2("THE CROWQUISTADOR CROSSING · A FIRST ENCOUNTER","EL CRUCE DEL CROWQUISTADOR · PRIMER ENCUENTRO"),17,GOLD)
	column.add_child(small)
	var portrait := TextureRect.new()
	portrait.texture = player.character_texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(size.x*.66,220)
	portrait.size = Vector2(size.x*.26,360)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(portrait)
	var language := _button("Español" if locale=="en" else "English",func():
		locale = "es" if locale=="en" else "en"
		save.data.locale = locale
		save.write_save()
		_show_menu())
	language.position = Vector2(size.x-maxf(210,size.x-safe.end.x+190),35)
	modal.add_child(language)

func _show_intro() -> void:
	current_screen = "intro"
	var column := _center_card()
	_copy(column,tr2("She has a plan. She needs your words.","Ella tiene un plan. Necesita tus palabras."),43,true)
	_copy(column,tr2("Xochi wants to bring her friends to the fiesta.\nCalabrija knows a route past a very proud crow.","Xochi quiere llevar a sus amigos a la fiesta.\nCalabrija conoce un camino junto a un cuervo muy orgulloso."),27)
	_copy(column,tr2("Hear the Spanish, then speak or choose what it means.\nXochi handles the footsteps and waits at new hazards.","Escucha el español y habla o elige su significado.\nXochi se encarga de los pasos y espera ante nuevos peligros."),25)
	_copy(column,tr2("Swipe and hold to move · Swipe up twice to double-jump\nTap to hyper-jump · Your touch always takes over.","Desliza y mantén para moverte · Dos deslizamientos arriba: doble salto\nToque: hipersalto · Tu mano siempre tiene el control."),22)
	var begin := _button(tr2("Let's go together","Vamos juntas"),_start_journey,true)
	begin.name = "StartJourney"
	column.add_child(begin)

func _start_journey() -> void:
	_clear_modal()
	step = 0
	playing = true
	finished = false
	retrying = false
	pending_answer.clear()
	session_uses.clear()
	session_choices.clear()
	session_spoken = 0
	friends_arrived = false
	retry_count = 0
	curiosity_time = 0.0
	curiosity_seen = false
	player.reset_at(world.to_global(Vector2(130,555)))
	player.active = true
	guard.reset_state()
	guard.active = true
	_enter_step()

func _enter_step() -> void:
	current_screen = "game"
	pending_answer.clear()
	hint_used = false
	waiting_time = 0
	controller.wait_here()
	_new_context()
	if step == 5: guard.distract("bell")
	if step == 6: friends_arrived = true
	calabrija.set_mood("helpful" if step >= 3 else "curious")
	_build_hud()

func submit_intent(intent: String, language := "es", source := "touch", expected_generation := -1) -> bool:
	if not playing or finished or retrying or get_tree().paused: return false
	if expected_generation >= 0 and expected_generation != generation: return false
	if not pending_answer.is_empty():
		if controller.guiding: return false
		pending_answer.clear()
	if intent == "now": intent = "jump"
	var lesson: Dictionary = LESSONS[step]
	if intent != lesson.intent:
		voice.stop()
		hint_used = true
		_status(tr2("A different idea. Hear the words again—there is time.","Otra idea. Escucha de nuevo; hay tiempo."),5)
		return false
	_new_context()
	pending_answer = {"intent":intent,"language":language,"source":source,"assisted":hint_used or language=="en"}
	waiting_time = 0
	if intent == "wait":
		controller.wait_here()
		_status(tr2("“Espera.” She waits with you.","«Espera». Ella espera contigo."),2)
	else:
		if step == 5 and not guard.can_cross():
			pending_answer.clear()
			_status(tr2("He is still watching. The opening will return.","Todavía está mirando. Habrá otra oportunidad."),4)
			return false
		var started: bool = controller.guide_to(world.to_global(lesson.target),lesson.jump)
		if not started:
			pending_answer.clear()
			_status(tr2("Release your touch, then give her the plan again.","Suelta el dedo y vuelve a darle el plan."),4)
			return false
		_status(tr2("She understood. You can take over with a swipe.","Te entendió. Puedes tomar el control deslizando."),4)
	for button in choice_buttons: button.disabled = true
	mic_button.disabled = true
	hear_button.disabled = true
	return true

func _complete_step() -> void:
	if pending_answer.is_empty(): return
	var answer := pending_answer.duplicate()
	pending_answer.clear()
	var intent: String = answer.intent
	session_uses[intent] = true
	if answer.source=="touch" and not answer.assisted: session_choices[intent] = true
	if answer.source=="voice" and answer.language=="es": session_spoken += 1
	save.record(intent,answer.source,answer.language,answer.assisted)
	save.write_save()
	controller.wait_here()
	step += 1
	if step >= LESSONS.size(): _finish()
	else: _enter_step()

func _voice_intent(intent: String, language: String, context: int) -> void:
	submit_intent(intent,language,"typed" if voice.last_source=="typed" else "voice",context)

func _voice_status(message: String) -> void:
	if not playing or finished: return
	if not voice.listening and not voice.requesting and not message.is_empty():
		_status(message,4)

func _manual_takeover() -> void:
	if not playing or finished: return
	_new_context()
	# An accepted destination may still be reached by hand. The next new
	# instruction replaces it; a stale speech result cannot resume movement.
	for button in choice_buttons: button.disabled = false
	if is_instance_valid(mic_button): mic_button.disabled = false
	if is_instance_valid(hear_button): hear_button.disabled = false
	_status(tr2("Your touch leads. Double-jump and hyper-jump are yours.","Tu mano guía. Tú controlas el doble salto y el hipersalto."),4)

func _guidance_failed(_reason: String) -> void:
	if not playing or finished: return
	pending_answer.clear()
	for button in choice_buttons: button.disabled = false
	if is_instance_valid(mic_button): mic_button.disabled = false
	if is_instance_valid(hear_button): hear_button.disabled = false
	_status(tr2("She stopped safely. Rejoin the lantern or try the plan again.","Se detuvo. Vuelve al farol o repite el plan."),5)

func _retry() -> void:
	if retrying or not playing or finished: return
	retrying = true
	retry_count += 1
	var start := Time.get_ticks_msec()
	controller.cancel_guidance()
	pending_answer.clear()
	_new_context()
	player.active = false
	player.clear_input()
	guard.active = false
	for button in choice_buttons: button.disabled = true
	if is_instance_valid(mic_button): mic_button.disabled = true
	if is_instance_valid(hear_button): hear_button.disabled = true
	var token := generation
	_status(tr2("A breath. The song stays with you.","Un respiro. La canción sigue contigo."),3)
	await get_tree().create_timer(0.48,false).timeout
	if token != generation or not playing or finished:
		return
	player.reset_at(world.to_global(LESSONS[step].spawn))
	player.active = true
	retrying = false
	guard.reset_state()
	guard.active = true
	retry_latencies.append((Time.get_ticks_msec()-start)/1000.0)
	_enter_step()

func _toggle_mic() -> void:
	if controller.guiding: return
	if not player.is_on_floor():
		_status(tr2("Land first, then give her a plan.","Aterriza primero y luego dale un plan."),3)
		return
	pending_answer.clear()
	for button in choice_buttons: button.disabled = false
	if voice.listening or voice.requesting:
		voice.stop()
		return
	controller.wait_here()
	if voice.available:
		voice.listen()
	else: _type_guidance()

func _hear() -> void:
	if not playing or finished: return
	if controller.guiding: return
	if not player.is_on_floor(): return
	pending_answer.clear()
	for button in choice_buttons: button.disabled = false
	voice.stop()
	controller.wait_here()
	voice.speak_example(LESSONS[step].phrase)
	example_duck_time = 3.2
	_status(tr2("Listen, then give Xochi a plan.","Escucha y dale un plan a Xochi."),4)

func _meaning() -> void:
	hint_used = true
	_status(LESSONS[step].meaning,6)

func _type_guidance() -> void:
	get_tree().paused = true
	var column := _center_card(760)
	_copy(column,tr2("Give her a plan","Dale un plan"),42,true)
	_copy(column,tr2("Type Spanish or English. Voice recognition is available on supported iPhones.","Escribe en español o inglés. La voz funciona en iPhone compatibles."),25)
	var field := LineEdit.new()
	field.name = "GuidanceText"
	field.placeholder_text = tr2("e.g. espera","por ejemplo: espera")
	field.custom_minimum_size.y = 80
	field.add_theme_font_override("font",body_font)
	field.add_theme_font_size_override("font_size",30)
	column.add_child(field)
	var send := func():
		var parser = load("res://scripts/spanish_intents.gd")
		var result: Dictionary = parser.match_phrase(field.text)
		get_tree().paused = false
		_clear_modal()
		if result.is_empty():
			_status(tr2("Try a short plan: ven, espera, al bote, al puente, salta.","Prueba un plan breve: ven, espera, al bote, al puente, salta."),6)
		else: submit_intent(result.intent,result.language,"typed")
	column.add_child(_button(tr2("Tell Xochi","Decírselo a Xochi"),send,true))
	column.add_child(_button(tr2("Back","Volver"),func(): get_tree().paused=false; _clear_modal()))
	field.text_submitted.connect(func(_text: String): send.call())
	field.grab_focus()

func _pause() -> void:
	if not playing or finished or is_instance_valid(modal): return
	current_screen = "pause"
	controller.cancel_guidance()
	player.clear_input()
	_new_context()
	get_tree().paused = true
	var column := _center_card(780)
	_copy(column,tr2("Take a breath","Toma un respiro"),48,true)
	_copy(column,tr2("Your words and the song stay with you.","Tus palabras y la canción siguen contigo."),26)
	column.add_child(_button(tr2("Keep going","Seguir"),_resume,true))
	column.add_child(_button(tr2("Listening language: ","Idioma de voz: ")+("Español" if voice_language=="es" else "English"),func():
		voice_language = "en" if voice_language=="es" else "es"
		save.data.voice_language = voice_language
		save.write_save()
		voice.configure(voice_language)
		_resume()
		_pause()))
	column.add_child(_button(tr2("Music: ","Música: ")+tr2("on" if save.data.music else "off","sí" if save.data.music else "no"),func():
		save.data.music = not save.data.music
		save.write_save()
		music.volume_db = -9 if save.data.music else -80
		_resume()
		_pause()))
	column.add_child(_button(tr2("Return to title","Volver al inicio"),_show_menu))

func _resume() -> void:
	get_tree().paused = false
	_clear_modal()
	current_screen = "game"
	_finish_interrupted_retry()
	pending_answer.clear()
	_new_context()
	for button in choice_buttons: button.disabled = false
	if is_instance_valid(mic_button): mic_button.disabled = false
	if is_instance_valid(hear_button): hear_button.disabled = false

func _finish() -> void:
	finished = true
	current_screen = "ending"
	controller.wait_here()
	player.clear_input()
	player.active = false
	guard.active = false
	_new_context()
	save.data.completed = true
	save.write_save()
	scenery.completed = true
	if is_instance_valid(hud): hud.hide()
	var column := _center_card(800)
	_copy(column,tr2("You found the words. She found the way.","Encontraste las palabras. Ella encontró el camino."),44,true)
	_copy(column,tr2("The little ones reach the fiesta.\nEven the Crowquistador pauses to listen.","Los pequeños llegan a la fiesta.\nHasta el Crowquistador se detiene para escuchar."),26)
	_copy(column,"Ven.  Espera.  Al bote.  Salta.  Al puente.",29)
	_copy(column,tr2("Spanish meanings chosen without a translation: ","Significados elegidos sin traducción: ")+str(session_choices.size())+" / 5\n"+tr2("Spoken Spanish practice: ","Práctica oral en español: ")+str(session_spoken),23)
	_copy(column,tr2("Next time, try guiding her without the English meaning.","La próxima vez, intenta guiarla sin consultar el significado."),22)
	column.add_child(_button(tr2("Another journey together","Otro viaje juntas"),_start_journey,true))
	column.add_child(_button(tr2("Back to the garden","Volver al jardín"),_show_menu))

func _build_hud() -> void:
	if is_instance_valid(hud):
		hud.hide()
		ui.remove_child(hud)
		hud.queue_free()
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	var size := get_viewport_rect().size
	var safe := _safe_rect()
	var left := maxf(65,safe.position.x+18)
	var right := maxf(65,size.x-safe.end.x+18)
	var width := size.x-left-right
	var top := maxf(22,safe.position.y+12)
	var header := PanelContainer.new()
	header.position = Vector2(left,top)
	header.size = Vector2(width-145,166)
	header.add_theme_stylebox_override("panel",_style(Color(.025,.14,.16,.95),22))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(header)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(column)
	var lesson: Dictionary = LESSONS[step]
	progress_label = _label(tr2(lesson.title,lesson.title_es)+"   ·   "+str(step+1)+" / "+str(LESSONS.size()),21,GOLD)
	column.add_child(progress_label)
	phrase_label = _label(lesson.phrase,46,CREAM,true)
	column.add_child(phrase_label)
	story_label = _label(tr2(lesson.story,lesson.story_es),24)
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(story_label)
	var pause := _button(tr2("Pause","Pausa"),_pause)
	pause.name = "Pause"
	pause.position = Vector2(size.x-right-130,top)
	pause.custom_minimum_size.x = 130
	hud.add_child(pause)
	var retry := _button(tr2("Rejoin","Volver"),_retry)
	retry.name = "Rejoin"
	retry.custom_minimum_size.x = 130
	retry.position = Vector2(size.x-right-130,top+96)
	hud.add_child(retry)
	var bottom := maxf(24,size.y-safe.end.y+12)
	var row := HBoxContainer.new()
	row.position = Vector2(left,size.y-bottom-92)
	row.size = Vector2(width,92)
	row.add_theme_constant_override("separation",10)
	hud.add_child(row)
	hear_button = _button(tr2("Hear it","Escuchar"),_hear)
	hear_button.name = "Hear"
	row.add_child(hear_button)
	mic_button = _button(tr2("Speak","Hablar"),_toggle_mic)
	mic_button.name = "Speak"
	row.add_child(mic_button)
	choice_buttons.clear()
	for intent in lesson.choices:
		var button := _button(_action_label(intent),func(): submit_intent(intent,"es","touch"),true)
		button.name = "Action_" + intent
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
		choice_buttons.append(button)
	var hint := _button(tr2("Meaning","Significado"),_meaning)
	hint.name = "Meaning"
	row.add_child(hint)
	status_label = _label("",23)
	status_label.position = Vector2(left,top+192)
	status_label.size = Vector2(width,34)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Backing prevents the moving water from reducing the instruction contrast.
	var status_back := Panel.new()
	status_back.position = status_label.position-Vector2(8,4)
	status_back.size = status_label.size+Vector2(16,8)
	status_back.add_theme_stylebox_override("panel",_style(Color(.025,.14,.16,.94),12))
	status_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(status_back)
	hud.add_child(status_label)
	_refresh_status()

func _action_label(intent: String) -> String:
	match intent:
		"come": return tr2("Come closer","Acercarse")
		"wait": return tr2("Wait here","Esperar")
		"boat": return tr2("Take the boat","Ir al bote")
		"bridge": return tr2("To the bridge","Ir al puente")
		"jump": return tr2("Jump across","Saltar")
	return intent

func _status(message: String, seconds := 4.0) -> void:
	status_text = message
	status_left = seconds
	_refresh_status()

func _refresh_status() -> void:
	if is_instance_valid(status_label):
		status_label.text = status_text if not status_text.is_empty() else tr2("Hear the Spanish. Speak, or choose its meaning.","Escucha el español. Habla o elige su significado.")

func _label(text: String, font_size := 25, color := CREAM, serif := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font",title_font if serif else body_font)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _style(color: Color, radius := 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _button(text: String, callback: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(145,90)
	button.add_theme_font_override("font",body_font)
	button.add_theme_font_size_override("font_size",25)
	button.add_theme_color_override("font_color",INK if primary else CREAM)
	button.add_theme_color_override("font_hover_color",INK)
	button.add_theme_color_override("font_pressed_color",INK)
	button.add_theme_color_override("font_disabled_color",Color("aac7bd"))
	button.add_theme_stylebox_override("normal",_style(GOLD if primary else Color(.025,.14,.16,.97)))
	button.add_theme_stylebox_override("hover",_style(CREAM))
	button.add_theme_stylebox_override("pressed",_style(PINK))
	button.add_theme_stylebox_override("disabled",_style(Color("315d5c")))
	var focus := _style(Color(0,0,0,0))
	focus.border_color = CREAM
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("focus",focus)
	button.pressed.connect(callback)
	return button

func _make_modal() -> void:
	_clear_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(.01,.07,.09,.66)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)

func _clear_modal() -> void:
	if is_instance_valid(modal):
		modal.hide()
		ui.remove_child(modal)
		modal.queue_free()
	modal = null

func _center_card(width := 810.0) -> VBoxContainer:
	_make_modal()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_style(Color(.025,.14,.16,.99),26))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = minf(width,_safe_rect().size.x-80)
	column.add_theme_constant_override("separation",10)
	panel.add_child(column)
	return column

func _copy(column: VBoxContainer, text: String, font_size: int, serif := false) -> Label:
	var label := _label(text,font_size,CREAM,serif)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(label)
	return label

func _safe_rect() -> Rect2:
	var size := get_viewport_rect().size
	if OS.has_feature("ios") or OS.has_feature("android"):
		var screen_size := Vector2(DisplayServer.window_get_size())
		var safe := DisplayServer.get_display_safe_area()
		if screen_size.x>0 and screen_size.y>0 and safe.size.x>0:
			return Rect2(Vector2(safe.position)*size/screen_size,Vector2(safe.size)*size/screen_size)
	return Rect2(Vector2.ZERO,size)

func _resize_ui() -> void:
	if not is_instance_valid(ui) or _resize_pending: return
	_resize_pending = true
	call_deferred("_apply_resize")

func _apply_resize() -> void:
	_resize_pending = false
	controller.cancel_guidance()
	_new_context()
	_layout_world()
	_finish_interrupted_retry()
	if current_screen=="menu": _show_menu()
	elif current_screen=="intro": _show_intro()
	elif current_screen=="ending": _finish()
	elif current_screen=="game":
		pending_answer.clear()
		_build_hud()

func _finish_interrupted_retry() -> void:
	if retrying and playing and not finished:
		retrying = false
		player.reset_at(world.to_global(LESSONS[step].spawn))
		player.active = true
		guard.reset_state()
		guard.active = true

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED] and playing and not finished:
		_pause()
