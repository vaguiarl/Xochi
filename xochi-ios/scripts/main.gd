extends Node2D
## One authored chapter. World state resets in place; audio and UI never reload.
const CREAM = Color("fff0d1")
const GOLD = Color("efc580")
const INK = Color("103e46")
const PINK = Color("f5b5ba")
const SPAWNS = [Vector2(170,555),Vector2(1460,555),Vector2(2790,555),Vector2(4190,555)]
var save = load("res://scripts/progress.gd").new()
var locale := "en"
var world: Node2D
var player: CharacterBody2D
var boss: Node2D
var camera: Camera2D
var scenery: Node2D
var ui: Control
var hud: Control
var modal: Control
var music: AudioStreamPlayer
var music_spare: AudioStreamPlayer
var music_tween: Tween
var music_track := "music_gardens"
var voice: Node
var title_font: Font
var body_font: Font
var platforms: Array = []
var enemies: Array = []
var flowers: Array[Vector2] = []
var collected: Dictionary = {}
var checkpoint_collected: Dictionary = {}
var checkpoint := 0
var attempt := 0
var deaths := 0
var courage := false
var playing := false
var finished := false
var retrying := false
var boss_started := false
var chapter_time := 0.0
var run_time := 0.0
var run_deaths := 0
var toast_timer := 0.0
var toast_label: Label
var toast_panel: Panel
var counter_label: Label
var status_label: Label
var charge_label: Label
var courage_button: Button
var mic_button: Button
var current_screen := "menu"
var sfx_players: Array[AudioStreamPlayer] = []
var retry_latencies: Array[float] = []

func tr2(en: String, es: String) -> String:
	return es if locale == "es" else en

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	title_font = load("res://assets/title.ttf")
	body_font = load("res://assets/body.ttf")
	save.read_save()
	locale = save.data.locale
	deaths = save.data.deaths
	var background = CanvasLayer.new()
	background.layer = -10
	add_child(background)
	scenery = load("res://scripts/scenery.gd").new()
	scenery.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	background.add_child(scenery)
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	_build_level()
	_build_audio()
	var layer = CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var input_router = load("res://scripts/ui_input.gd").new()
	input_router.main = self
	layer.add_child(input_router)
	if ResourceLoader.exists("res://scripts/voice_support.gd"):
		voice = load("res://scripts/voice_support.gd").new()
		add_child(voice)
		voice.encouragement.connect(_grant_courage)
		voice.status_changed.connect(_voice_status)
	get_viewport().size_changed.connect(_resize_ui)
	_show_menu()
	if "--mvp-smoke" in OS.get_cmdline_user_args():
		call_deferred("_run_smoke")

func _build_level() -> void:
	var data = [
		[0,555,650,false,Vector2.ZERO], [765,505,170,true,Vector2(0,12)],
		[1050,445,180,true,Vector2.ZERO], [1350,555,310,false,Vector2.ZERO],
		[1780,505,180,true,Vector2(35,22)], [2090,430,135,true,Vector2.ZERO],
		[2355,505,155,true,Vector2(0,28)], [2640,555,355,false,Vector2.ZERO],
		[3120,470,125,true,Vector2(28,0)], [3390,395,140,true,Vector2.ZERO],
		[3680,485,150,true,Vector2.ZERO], [3970,555,1450,false,Vector2.ZERO]
	]
	for d in data:
		var platform = load("res://scripts/platform.gd").new()
		platform.configure(Rect2(d[0],d[1],d[2],20),d[3],d[4])
		world.add_child(platform)
		platforms.append(platform)
		if d[3]:
			flowers.append(Vector2(d[0]+d[2]*.5,d[1]-75))
	player = load("res://scripts/player.gd").new()
	player.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	player.name = "Xochi"
	world.add_child(player)
	if ResourceLoader.exists("res://assets/xochi.png"):
		player.character_texture = load("res://assets/xochi.png")
	if ResourceLoader.exists("res://assets/xochi-actions.png"):
		player.character_atlas = load("res://assets/xochi-actions.png")
	player.reset_at(SPAWNS[0])
	player.active = false
	player.died.connect(_on_death)
	player.ripple.connect(_on_ripple)
	player.jumped.connect(func(hyper: bool): _sfx("jump_super" if hyper else "jump_small",-16))
	camera = Camera2D.new()
	camera.position = Vector2(640,360)
	camera.position_smoothing_enabled = false
	add_child(camera)
	for spec in [["crow",Vector2(1130,270),Vector2(-90,90)],["jaguar",Vector2(2180,430),Vector2(-60,15)],["crow",Vector2(2470,270),Vector2(-75,75)],["crow",Vector2(3440,200),Vector2(-80,80)],["jaguar",Vector2(3760,485),Vector2(-50,45)]]:
		var enemy = load("res://scripts/enemy.gd").new()
		world.add_child(enemy)
		enemy.configure(spec[0],spec[1],player,spec[2])
		enemy.active = false
		enemies.append(enemy)
	boss = load("res://scripts/boss.gd").new()
	world.add_child(boss)
	boss.configure(Vector2(4830,555),player)
	if player.character_texture: boss.character_texture = player.character_texture
	boss.active = false
	boss.defeated.connect(_on_win)
	boss.phase_changed.connect(_boss_tell)

func _build_audio() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,"Music")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),not save.data.music)
	music = AudioStreamPlayer.new()
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	music.bus = "Music"
	add_child(music)
	var stream = load("res://assets/audio/music/music_gardens.ogg")
	stream.loop = true
	music.stream = stream
	music.volume_db = -9
	music.play()
	music_spare = AudioStreamPlayer.new()
	music_spare.bus = "Music"
	music_spare.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_spare)
	for i in 5:
		var sound = AudioStreamPlayer.new()
		add_child(sound)
		sfx_players.append(sound)

func _crossfade_music(track: String) -> void:
	if music_track == track: return
	music_track = track
	if music_tween and music_tween.is_valid(): music_tween.kill()
	var outgoing = music
	music = music_spare
	music_spare = outgoing
	music.stop()
	music.stream = null
	music.stream = load("res://assets/audio/music/"+track+".ogg")
	music.stream.loop = true
	music.volume_db = -60
	music.play()
	music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	music_tween.set_parallel(true)
	music_tween.tween_property(music,"volume_db",-9.0,2.5)
	music_tween.tween_property(outgoing,"volume_db",-60.0,2.5)
	music_tween.chain().tween_callback(outgoing.stop)

func _sfx(name_: String, volume := -12.0) -> void:
	for sound in sfx_players:
		if not sound.playing:
			sound.stream = load("res://assets/audio/sfx/"+name_+".ogg")
			sound.volume_db = volume
			sound.play()
			break

func _process(delta: float) -> void:
	chapter_time += delta
	if playing and not finished:
		run_time += delta
		var size = get_viewport_rect().size
		var goal_x = clampf(player.position.x+190,size.x/2,5420-size.x/2)
		camera.position.x = lerpf(camera.position.x,goal_x,1-exp(-delta*6))
		camera.position.y = size.y/2
		scenery.scroll = maxf(0,camera.position.x-size.x/2)
		if not retrying:
			if player.position.y > 735 or player.position.x < -30:
				player.take_hit()
			for i in range(checkpoint+1,4):
				if player.position.x >= SPAWNS[i].x-35 and player.position.y <= 575:
					_reach_checkpoint(i)
			for i in flowers.size():
				if not collected.has(i) and player.position.distance_to(flowers[i]) < 52:
					collected[i] = true
					_sfx("flower",-18)
			if checkpoint == 3 and player.position.x > 4440: boss_started = true
			boss.active = boss_started
		_update_hud()
	if toast_timer > 0:
		toast_timer -= delta
		if is_instance_valid(toast_label): toast_label.modulate.a = minf(1,toast_timer)
		if is_instance_valid(toast_panel): toast_panel.modulate.a = minf(1,toast_timer)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player): return
	for i in flowers.size():
		if collected.has(i): continue
		var p = flowers[i]+Vector2(0,sin(chapter_time*2+i)*5)
		for petal in 6:
			draw_circle(p+Vector2.from_angle(petal*TAU/6+chapter_time*.2)*5,5,Color("ffd28b"))
		draw_circle(p,3,Color("fff5cf"))
	for i in 4:
		var p = SPAWNS[i]+Vector2(-60,-2)
		draw_line(p,p+Vector2(0,-100),Color("b8996e"),4)
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-100),p+Vector2(48,-88),p+Vector2(0,-70)]),GOLD if i<=checkpoint else Color("7c9590"))
		draw_circle(p+Vector2(0,-106),6,CREAM)
	# Little friends wait on safe land; the last is held by the reflection.
	for i in 3:
		var p = Vector2([1520,2860,5000][i],540)
		var rescued = checkpoint > i if i < 2 else finished
		var c = Color("f3c3bc") if rescued else Color("bfc6ce")
		if player.character_texture:
			draw_texture_rect(player.character_texture,Rect2(p.x-25,p.y-28,50,44),false,Color.WHITE if rescued else Color(.75,.8,1))
			continue
		draw_set_transform(p,0,Vector2(.6,.6))
		draw_circle(Vector2(0,-10),20,c)
		for side in [-1,1]:
			for gill in 3:
				draw_line(Vector2(side*16,-15),Vector2(side*(28+gill*2),-26+gill*10),Color("d491a6"),5)
			draw_circle(Vector2(side*7,-13),2.5,INK)
		draw_arc(Vector2(0,-8),5,0,PI,12,INK,1.5,true)
		draw_set_transform(Vector2.ZERO)
	if finished:
		for i in 80:
			var p = Vector2(4300+fposmod(i*71.1+chapter_time*12,950),fposmod(i*91.2+chapter_time*(25+i%6),570))
			draw_circle(p,2+i%3,[GOLD,PINK,Color("a5d8b7")][i%3])

func _start(resume: bool) -> void:
	_clear_modal()
	get_tree().paused = false
	checkpoint = int(save.data.checkpoint) if resume else 0
	courage = bool(save.data.courage) if resume else false
	finished = false
	if voice: voice.set_locale(locale)
	playing = true
	retrying = false
	run_time = 0
	run_deaths = 0
	_crossfade_music("music_gardens")
	collected.clear()
	checkpoint_collected.clear()
	if resume:
		for id in save.data.flowers: checkpoint_collected[int(id)] = true
	attempt += 1
	save.data.completed = false
	_reset_world()
	_build_hud()
	current_screen = "game"
	if checkpoint == 0:
		_toast(tr2("Swipe to move · swipe up to jump · tap to hyper-jump · hold to ripple", "Desliza para moverte · arriba: salto · toque: hipersalto · mantén: onda"),12)
	else:
		_toast(tr2("A fresh breath. Your friends are waiting.","Un nuevo respiro. Tus amigos te esperan."),5)
	_persist()

func _reset_world() -> void:
	collected = checkpoint_collected.duplicate()
	scenery.completed = false
	boss_started = false
	for platform in platforms: platform.reset_state()
	for enemy in enemies:
		enemy.reset_state()
		enemy.active = true
	boss.reset_state()
	boss.active = false
	player.reset_at(SPAWNS[checkpoint],courage)
	player.active = true
	camera.position = Vector2(clampf(player.position.x+190,get_viewport_rect().size.x/2,5420-get_viewport_rect().size.x/2),get_viewport_rect().size.y/2)
	camera.reset_smoothing()
	if voice: voice.stop()

func _reach_checkpoint(index: int) -> void:
	checkpoint = index
	checkpoint_collected = collected.duplicate()
	courage = false
	player.hyper_charges = 2
	player.reserve_available = false
	player.invulnerable = 1.0
	if voice: voice.stop()
	_sfx("powerup",-16)
	_persist()
	var lines = ["",tr2("“We thought that shadow was you.”  —  One friend home.","«Pensamos que esa sombra eras tú».  —  Un amigo a salvo."),tr2("“She hid us where the storm couldn't reach.”  —  Two friends home.","«Nos escondió donde no llegaba la tormenta».  —  Dos amigos a salvo."),tr2("Your reflection holds the last friend. Wait for her light to open, then Ripple.","Tu reflejo guarda al último amigo. Espera a que se abra su luz y usa la onda.")]
	_toast(lines[index],8)

func _on_death() -> void:
	if retrying or finished or not playing: return
	retrying = true
	var started = Time.get_ticks_msec()
	var token = attempt
	deaths += 1
	run_deaths += 1
	player.active = false
	if voice: voice.stop()
	_sfx("hurt",-21)
	await get_tree().create_timer(.48,false).timeout
	if token != attempt or finished or not playing: return
	attempt += 1
	_reset_world()
	retrying = false
	retry_latencies.append((Time.get_ticks_msec()-started)/1000.0)
	_toast(tr2("Still with you. Try again.","Sigo contigo. Una vez más."),2)
	_persist()

func _on_ripple(origin: Vector2, direction: float) -> void:
	for enemy in enemies: enemy.receive_ripple(origin,direction)
	boss.receive_ripple(origin,direction)
	_sfx("stomp",-22)

func _grant_courage() -> void:
	if not playing or finished or retrying or get_tree().paused or courage: return
	courage = true
	player.reserve_available = true
	_sfx("powerup",-14)
	_toast(tr2("Second Wind · one reserve hyper-jump. It returns with every retry.","Segundo aliento · un hipersalto de reserva. Vuelve en cada intento."),5)
	if voice: voice.stop()
	_persist()

func _voice_status(message: String) -> void:
	if is_instance_valid(status_label): status_label.text = message

func _toggle_mic() -> void:
	if not playing or finished or retrying or get_tree().paused: return
	if not voice or not voice.available:
		_toast(tr2("Voice isn't available here. Courage gives exactly the same boost.","La voz no está disponible aquí. Ánimo da el mismo impulso."),5)
		return
	if voice.listening or voice.requesting:
		voice.stop()
	else:
		voice.start(locale,checkpoint,attempt)
		_toast(tr2("When the mic shows Listening, say “You've got this!” · Tap Voice to stop.","Cuando indique Escuchando, di «¡Vamos, Xochi!» · Toca Voz para parar."),6)

func _boss_tell(tell: String) -> void:
	if not playing or finished: return
	# Enemy state is authoritative. Translate its finite vocabulary, never runtime prose.
	if boss.state == "exposed" or "exposed" in tell.to_lower() or "open" in tell.to_lower():
		_toast(tr2("Now! Send a Ripple to your reflection.","¡Ahora! Envía una onda a tu reflejo."),2)
	elif tell == "leap":
		_toast(tr2("She's landing at the glowing mark. Move out, then come close.","Caerá en la marca brillante. Aléjate y luego acércate."),2)
	elif tell == "wave":
		_toast(tr2("A low ripple is coming. Jump over it!","Viene una onda baja. ¡Salta sobre ella!"),2)

func _on_win() -> void:
	if finished: return
	finished = true
	player.active = false
	player.clear_input()
	for enemy in enemies: enemy.active = false
	boss.active = false
	if voice: voice.stop()
	scenery.completed = true
	_crossfade_music("music_finale")
	save.data.completed = true
	_update_hud()
	_persist()
	_toast(tr2("“You can let go. We'll go home together.”","«Puedes soltar. Volvamos a casa juntas»."),4)
	var ending_attempt = attempt
	await get_tree().create_timer(3,false).timeout
	if finished and playing and ending_attempt == attempt: _show_ending()

func _persist() -> void:
	save.data.checkpoint = checkpoint
	save.data.courage = courage
	save.data.locale = locale
	save.data.deaths = deaths
	save.data.flowers = checkpoint_collected.keys()
	if not save.write_save():
		_toast(tr2("Progress couldn't be saved. Please check free storage.","No se pudo guardar. Revisa el espacio disponible."),6)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		if is_instance_valid(player): player.clear_input()
		if is_instance_valid(voice): voice.stop()
		if playing and not finished and is_instance_valid(ui): _pause()

func _exit_tree() -> void:
	if is_instance_valid(voice): voice.stop()
	for channel in [music,music_spare]:
		if is_instance_valid(channel):
			channel.stop()
			channel.stream = null

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C: _grant_courage()

func _resize_ui() -> void:
	if not is_instance_valid(ui): return
	if playing: _build_hud()
	match current_screen:
		"menu": _show_menu()
		"intro": _show_intro()
		"pause": _pause()
		"ending": _show_ending()

func _clear_modal() -> void:
	if is_instance_valid(modal):
		modal.queue_free()
		modal = null

func _label(text_: String, size_: int, color: Color = CREAM, serif := false) -> Label:
	var label = Label.new()
	label.text = text_
	label.add_theme_font_override("font",title_font if serif else body_font)
	label.add_theme_font_size_override("font_size",size_)
	label.add_theme_color_override("font_color",color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _style(color: Color, radius := 18) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _button(text_: String, callback: Callable, primary := false) -> Button:
	var button = Button.new()
	button.text = text_
	button.custom_minimum_size = Vector2(165,84)
	button.add_theme_font_override("font",body_font)
	button.add_theme_font_size_override("font_size",21)
	button.add_theme_color_override("font_color",INK if primary else CREAM)
	button.add_theme_color_override("font_hover_color",INK)
	button.add_theme_color_override("font_disabled_color",Color("b7ddc8"))
	button.add_theme_stylebox_override("normal",_style(GOLD if primary else Color(.035,.17,.19,.93)))
	button.add_theme_stylebox_override("hover",_style(CREAM))
	button.add_theme_stylebox_override("pressed",_style(PINK))
	button.add_theme_stylebox_override("disabled",_style(Color(.06,.23,.23,.94)))
	button.add_theme_stylebox_override("focus",_style(Color(.85,.65,.4,.35)))
	button.pressed.connect(callback)
	button.focus_mode = Control.FOCUS_ALL
	return button

func _make_modal() -> Control:
	_clear_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(modal)
	var shade = ColorRect.new()
	shade.color = Color(.015,.085,.10,.64)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	return modal

func _center_card(width_: float = 710) -> VBoxContainer:
	_make_modal()
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_style(Color(.035,.15,.17,.96),28))
	center.add_child(panel)
	var column = VBoxContainer.new()
	column.custom_minimum_size.x = width_
	column.add_theme_constant_override("separation",15)
	panel.add_child(column)
	return column

func _copy(column: VBoxContainer, text_: String, size_: int, serif := false) -> Label:
	var label = _label(text_,size_,CREAM,serif)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	return label

func _show_menu() -> void:
	current_screen = "menu"
	attempt += 1
	playing = false
	player.active = false
	player.clear_input()
	if voice: voice.stop()
	for enemy in enemies: enemy.active = false
	boss.active = false
	camera.position = get_viewport_rect().size/2
	scenery.scroll = 0
	_crossfade_music("music_gardens")
	if is_instance_valid(hud): hud.hide()
	_make_modal()
	# Editorial title treatment lets the canal artwork carry the opening screen.
	var size = get_viewport_rect().size
	var column = VBoxContainer.new()
	column.position = Vector2(90,maxf(75,size.y*.16))
	column.size = Vector2(570,470)
	column.add_theme_constant_override("separation",12)
	modal.add_child(column)
	if player.character_texture:
		var portrait = TextureRect.new()
		portrait.texture = player.character_texture
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.position = Vector2(size.x*.65,size.y*.25)
		portrait.size = Vector2(size.x*.27,size.y*.63)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		modal.add_child(portrait)
	column.add_child(_label(tr2("A LITTLE HEART. A LONG WAY HOME.","UN CORAZÓN PEQUEÑO. UN GRAN VIAJE."),16,GOLD))
	column.add_child(_label("Xochi",110,CREAM,true))
	column.add_child(_label(tr2("The Song Home","La canción de regreso"),38,CREAM,true))
	var description = _label(tr2("Find your friends in the floating gardens.\nFall, breathe, and try again. The music stays with you.","Busca a tus amigos en los jardines flotantes.\nCae, respira y vuelve a intentar. La música sigue contigo."),21)
	column.add_child(description)
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 12
	column.add_child(spacer)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	column.add_child(row)
	row.add_child(_button(tr2("Begin the journey","Comenzar el viaje"),_show_intro,true))
	if save.data.checkpoint > 0 and not save.data.completed:
		row.add_child(_button(tr2("Continue","Continuar"),func(): _start(true)))
	var language = _button("Español" if locale == "en" else "English",func():
		locale = "es" if locale == "en" else "en"
		save.data.locale = locale
		save.write_save()
		_show_menu())
	language.position = Vector2(size.x-240,45)
	modal.add_child(language)
	var note = _label(tr2("ONE CHAPTER  /  ENDLESS SECOND CHANCES", "UN CAPÍTULO  /  TODAS LAS OPORTUNIDADES"),14,GOLD)
	note.position = Vector2(90,size.y-55)
	modal.add_child(note)

func _show_intro() -> void:
	current_screen = "intro"
	var column = _center_card()
	_copy(column,tr2("Before the lanterns wake","Antes de encender los faroles"),46,true)
	_copy(column,tr2("Last night, a storm scattered the little axolotls across the canals.\nXochi promised to bring every friend home before the fiesta.\n\nSomewhere in the water, her reflection made a promise too.","Anoche, una tormenta dispersó a los ajolotitos por los canales.\nXochi prometió traerlos a todos antes de la fiesta.\n\nEn algún rincón del agua, su reflejo también hizo una promesa."),23)
	_copy(column,tr2("Swipe and hold left / right · Double swipe to sprint\nSwipe up to jump · Tap for a hyper-jump · Hold for Ripple\n\nArrows / A D · Space · X · Z on a keyboard", "Desliza y mantén para avanzar · Dos deslizamientos para correr\nDesliza arriba para saltar · Toque: hipersalto · Mantén: onda\n\nFlechas / A D · Espacio · X · Z en teclado"),19)
	column.add_child(_button(tr2("Let's bring them home","Vamos a traerlos a casa"),func(): _start(false),true))

func _build_hud() -> void:
	if is_instance_valid(hud): hud.queue_free()
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	var size = get_viewport_rect().size
	var safe = _safe_rect()
	var left = maxf(70,safe.position.x+20)
	var right = maxf(70,size.x-safe.end.x+20)
	var top = maxf(25,safe.position.y+16)
	var bottom = maxf(44,size.y-safe.end.y+20)
	var plate = Panel.new()
	plate.position = Vector2(left,top)
	plate.size = Vector2(370,89)
	plate.add_theme_stylebox_override("panel",_style(Color(.025,.14,.16,.88)))
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(plate)
	counter_label = _label("",20)
	counter_label.position = Vector2(left+20,top+11)
	hud.add_child(counter_label)
	charge_label = _label("",17,GOLD)
	charge_label.position = Vector2(left+20,top+46)
	hud.add_child(charge_label)
	var pause = _button(tr2("Pause","Pausa"),_pause)
	pause.position = Vector2(size.x-right-165,top)
	hud.add_child(pause)
	courage_button = _button(tr2("Courage  +","Ánimo  +"),_grant_courage,true)
	courage_button.position = Vector2(size.x-right-190,size.y-bottom-84)
	courage_button.custom_minimum_size.x = 190
	hud.add_child(courage_button)
	mic_button = _button(tr2("Voice","Voz"),_toggle_mic)
	mic_button.position = Vector2(size.x-right-372,size.y-bottom-84)
	hud.add_child(mic_button)
	status_label = _label("",15)
	status_label.position = Vector2(size.x-right-440,size.y-bottom-114)
	status_label.size = Vector2(430,24)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(status_label)
	toast_panel = Panel.new()
	toast_panel.position = Vector2(100,125)
	toast_panel.size = Vector2(size.x-200,78)
	toast_panel.add_theme_stylebox_override("panel",_style(Color(.025,.14,.16,.90)))
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.modulate.a = 0
	hud.add_child(toast_panel)
	toast_label = _label("",23)
	toast_label.add_theme_color_override("font_shadow_color",Color("062c37"))
	toast_label.add_theme_constant_override("shadow_offset_x",2)
	toast_label.add_theme_constant_override("shadow_offset_y",2)
	toast_label.position = Vector2(120,133)
	toast_label.size = Vector2(size.x-240,64)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(toast_label)
	_update_hud()

func _safe_rect() -> Rect2:
	var viewport_size = get_viewport_rect().size
	if OS.has_feature("ios") or OS.has_feature("android"):
		var screen_size = Vector2(DisplayServer.window_get_size())
		var safe = DisplayServer.get_display_safe_area()
		if screen_size.x > 0 and screen_size.y > 0 and safe.size.x > 0:
			return Rect2(Vector2(safe.position)*viewport_size/screen_size,Vector2(safe.size)*viewport_size/screen_size)
	return Rect2(Vector2.ZERO,viewport_size)

func _update_hud() -> void:
	if not is_instance_valid(counter_label): return
	counter_label.text = tr2("Friends ","Amigos ")+str(3 if finished else mini(checkpoint,2))+" / 3   ·   "+tr2("Garden ","Jardín ")+str(checkpoint+1)+" / 4"
	charge_label.text = tr2("Hyper ","Hiper ")+"✦ ".repeat(player.hyper_charges)+("  + ✦" if player.reserve_available else "")
	courage_button.text = tr2("With you  ✓","Contigo  ✓") if courage else tr2("Courage  +","Ánimo  +")
	courage_button.disabled = courage
	mic_button.text = tr2("Listening •","Escuchando •") if voice and voice.listening else (tr2("Cancel mic","Cancelar voz") if voice and voice.requesting else tr2("Voice","Voz"))

func _toast(message: String, seconds := 4.0) -> void:
	if not is_instance_valid(toast_label): return
	toast_label.text = message
	toast_label.modulate.a = 1 if seconds > 0 and not message.is_empty() else 0
	toast_panel.modulate.a = toast_label.modulate.a
	toast_timer = seconds

func _pause() -> void:
	if not playing or finished: return
	current_screen = "pause"
	player.clear_input()
	if voice: voice.stop()
	get_tree().paused = true
	var column = _center_card(640)
	_copy(column,tr2("Take a breath","Toma un respiro"),48,true)
	_copy(column,tr2("The gardens can wait.\nYour song keeps playing.","Los jardines pueden esperar.\nTu canción sigue sonando."),23)
	column.add_child(_button(tr2("Keep going","Seguir"),_resume,true))
	column.add_child(_button(tr2("Retry this garden","Reintentar este jardín"),func():
		_resume()
		_on_death()))
	column.add_child(_button(tr2("Music: ","Música: ")+("ON" if save.data.music else "OFF"),func():
		save.data.music = not save.data.music
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),not save.data.music)
		save.write_save()
		_pause()))
	column.add_child(_button(tr2("Return to title","Volver al inicio"),func():
		get_tree().paused = false
		playing = false
		attempt += 1
		player.active = false
		for enemy in enemies: enemy.active = false
		boss.active = false
		_show_menu()))

func _resume() -> void:
	_clear_modal()
	player.clear_input()
	get_tree().paused = false
	current_screen = "game"

func _show_ending() -> void:
	current_screen = "ending"
	var column = _center_card(720)
	_copy(column,tr2("Everyone belongs in the song","Todos caben en la canción"),46,true)
	_copy(column,tr2("The shadow wasn't trying to hurt them. She was afraid to lose them.\nXochi offered her hand, and the water began to move again.\n\nThree friends. One reflection. All the way home.","La sombra no quería hacerles daño. Tenía miedo de perderlos.\nXochi le ofreció la mano y el agua volvió a fluir.\n\nTres amigos. Un reflejo. Todos de vuelta en casa."),23)
	_copy(column,tr2("The floating gardens are singing again.","Los jardines flotantes vuelven a cantar."),28,true)
	_copy(column,str(collected.size())+" / "+str(flowers.size())+tr2(" flowers  ·  "," flores  ·  ")+str(run_deaths)+tr2(" brave retries  ·  "," intentos valientes  ·  ")+"%d:%02d" % [int(run_time)/60,int(run_time)%60],19)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",16)
	column.add_child(row)
	row.add_child(_button(tr2("One more journey","Otro viaje"),func(): _start(false),true))
	row.add_child(_button(tr2("Title","Inicio"),_show_menu))

func _run_smoke() -> void:
	# Integration checks are explicit setup probes, not claims that an agent beat the game.
	var saved_progress = save.data.duplicate(true)
	_start(false)
	await get_tree().create_timer(.9,false).timeout
	assert(player.active and player.hyper_charges == 2)
	_grant_courage()
	assert(courage and player.reserve_available)
	var audio_stream_before = music.stream
	var music_before = music.get_playback_position()
	player.take_hit()
	await get_tree().create_timer(.65,false).timeout
	assert(not retrying and player.active and player.reserve_available and player.hyper_charges==2)
	assert(music.stream == audio_stream_before and music.playing)
	assert(music.get_playback_position() >= music_before)
	assert(retry_latencies[-1] < .8)
	_pause()
	var paused_pos = player.position
	var paused_boat = platforms[4].position
	await get_tree().create_timer(.2,true).timeout
	assert(player.position == paused_pos and platforms[4].position == paused_boat)
	_resume()
	_reach_checkpoint(1)
	assert(not courage and not player.reserve_available and player.hyper_charges == 2)
	_reach_checkpoint(3)
	_on_win()
	await get_tree().create_timer(3.1,false).timeout
	assert(finished and current_screen == "ending" and save.data.completed)
	save.data = saved_progress
	save.write_save()
	print("[MVP] integration PASS: retry=",retry_latencies," audio persistent, pause frozen, checkpoint/courage/ending")
	music.stop()
	music_spare.stop()
	await get_tree().create_timer(.05,true).timeout
	get_tree().quit(0)
