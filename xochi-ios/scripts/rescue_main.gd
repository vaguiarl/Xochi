extends "res://scripts/companion_main.gd"
## The Trajinera Rescue: progression belongs to the world, never a lesson index.
const COVERS := [990.0,1320.0,1660.0,2480.0,2850.0]
var boats: Dictionary = {}
var friends: Dictionary = {}
var rescued_ids: Array[String] = []
var checkpoint := Vector2(130,555)
var selected := "baby_one"
var plan: Array = []
var route_wait := 0.0
var departing := false
var departure_time := 0.0
var final_guard := false
var camera_x := 0.0
var camera: Camera2D
var markers: Dictionary = {}
var frozen_encounter := false
var bell_pulse := 0.0

func _build_world() -> void:
	camera = Camera2D.new()
	add_child(camera)
	for spec in [[0,500],[900,850],[1850,170],[2440,580]]:
		var platform = load("res://scripts/platform.gd").new()
		platform.configure(Rect2(spec[0],555,spec[1],20),false)
		world.add_child(platform)
	for spec in [["lupita","La Lupita",Vector2(600,555),Vector2(800,555),1,Color("f6d36c")],["frida","Frida",Vector2(2180,530),Vector2(2300,530),2,Color("f58d91")],["esperanza","Esperanza",Vector2(3170,555),Vector2(3170,555),3,Color("b6eed9")]]:
		var boat = load("res://scripts/trajinera.gd").new()
		if spec[0]=="esperanza": boat.width = 280
		boat.configure(spec[0],spec[1],spec[2],spec[3],spec[4],spec[5])
		world.add_child(boat)
		boats[spec[0]] = boat
	player = load("res://scripts/player.gd").new()
	player.name = "Xochi"
	player.z_index = 3
	player.character_texture = load("res://assets/xochi.png")
	player.character_atlas = load("res://assets/xochi-actions.png")
	world.add_child(player)
	player.reset_at(Vector2(130,555))
	player.active = false
	player.died.connect(_retry)
	for boat in boats.values(): boat.passenger = player
	controller = load("res://scripts/companion_controller.gd").new()
	add_child(controller)
	controller.configure(player)
	controller.manual_takeover.connect(_manual_takeover)
	controller.failed.connect(_guidance_failed)
	guard = load("res://scripts/crow_guard.gd").new()
	guard.z_index = 3
	world.add_child(guard)
	guard.target = player
	guard.configure(Vector2(1470,555))
	guard.active = false
	guard.caught.connect(_retry)
	guard.noticed.connect(func(): _status(tr2("He sees you! Run, hide in reeds, or ring the bell.","¡Te vio! Corre, escóndete entre juncos o toca la campana."),3))
	calabrija = load("res://scripts/calabrija.gd").new()
	calabrija.z_index = 4
	world.add_child(calabrija)
	calabrija.position = Vector2(360,350)
	for spec in [["baby_one",Vector2(260,555),false],["rabbit",Vector2(1320,555),true],["baby_two",Vector2(2180,530),false]]:
		var friend = load("res://scripts/rescue_friend.gd").new()
		friend.configure(spec[0],spec[1],spec[2])
		friend.leader = player
		friend.z_index = 2
		if spec[0]=="baby_two": friend.carrier = boats.frida
		world.add_child(friend)
		friend.rescued.connect(_rescue)
		friends[spec[0]] = friend

func _layout_world() -> void:
	world.position = Vector2.ZERO
	camera.position = get_viewport_rect().size/2+Vector2(camera_x,0)

func _process(delta: float) -> void:
	elapsed += delta
	bell_pulse = maxf(0,bell_pulse-delta)
	if playing and not finished:
		camera_x = move_toward(camera_x,clampf(player.position.x-500,0,2330),delta*maxf(500,absf(player.position.x-500-camera_x)*4))
		_layout_world()
		scenery.scroll = camera_x
		guard.bank_min = 2440 if final_guard else 900
		guard.bank_max = 3020 if final_guard else 1750
		guard.origin = world.to_global(Vector2(2780 if final_guard else 1470,555))
		guard.target_hidden = _in_cover()
		guard.active = not rescued_ids.is_empty() and not retrying and not departing
		if player.position.x>2440 and not final_guard:
			final_guard = true
			guard.configure(world.to_global(Vector2(2780,555)))
		if not retrying and not departing and (player.position.y>755 or player.position.x<15): _retry()
		var busy: bool = voice.listening or voice.requesting or voice.interpreting
		_freeze_encounter(busy)
		if busy != listening_before:
			listening_before = busy
		if is_instance_valid(mic_button): mic_button.text = tr2("Cancel","Cancelar") if busy else tr2("Speak","Hablar")
		example_duck_time = maxf(0,example_duck_time-delta)
		music.volume_db = move_toward(music.volume_db,-80 if not save.data.music else (-19 if busy or example_duck_time>0 else -9),delta*18)
		calabrija.position = calabrija.position.lerp(Vector2(guard.position.x+120,390) if bell_pulse>0 else player.position+Vector2(90,-170),minf(1,delta*3))
		if not busy and not retrying and not departing: _advance_plan(delta)
		if player.is_on_floor() and not departing:
			for x in COVERS:
				if absf(player.position.x-x)<36 and checkpoint.x!=x:
					checkpoint = Vector2(x,555)
					_save_rescue()
			if _aboard("esperanza"):
				if rescued_ids.size()==3: _begin_departure()
				elif status_left<=0:
					for id in friends:
						if id not in rescued_ids:
							selected = id if id!="baby_two" else "frida"
							break
					_build_hud()
					_status(tr2("A friend is missing. Guide returns to ","Falta un amigo. Guiar vuelve a ")+_name_for(selected),6)
		if departing:
			departure_time += delta
			if departure_time>3.2: _finish()
		_update_markers()
	if status_left>0:
		status_left -= delta
		if status_left<=0:
			status_text = ""
			_refresh_status()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(world): return
	var offset := world.position
	for x in COVERS:
		var p := offset+Vector2(x,555)
		draw_circle(p+Vector2(0,-55),57,Color(.4,.8,.6,.10))
		for i in 13:
			var base := p+Vector2((i-6)*8,5)
			var tip := base+Vector2(sin(elapsed+i)*5,-55-(i%3)*16)
			draw_line(base,tip,Color("47836a"),3,true)
			draw_line(tip,tip+Vector2(7,-9),GOLD,3,true)
		draw_string(body_font,p+Vector2(-34,30),"REFUGIO",HORIZONTAL_ALIGNMENT_LEFT,-1,15,CREAM)
	for x in [470,990,1320,1660,2480,2850]:
		var p := offset+Vector2(x,555)
		draw_line(p,p+Vector2(0,-100),Color("685a40"),4,true)
		draw_circle(p+Vector2(0,-100),20,Color(1,.72,.3,.14))
		draw_style_box(_style(GOLD,5),Rect2(p+Vector2(-7,-111),Vector2(14,22)))
	for x in [1640,2950]:
		var p := offset+Vector2(x,390)
		draw_line(p+Vector2(0,-30),p+Vector2(0,140),Color("685a40"),5)
		draw_circle(p,17,GOLD)
		draw_string(body_font,p+Vector2(-55,-40),"Mira allá",HORIZONTAL_ALIGNMENT_LEFT,-1,23,CREAM)
	if bridge_texture:
		draw_texture_rect(bridge_texture,Rect2(offset+Vector2(2540,557),Vector2(470,178)),false)

func _start_journey() -> void:
	get_tree().paused = false
	_clear_modal()
	playing = true
	finished = false
	retrying = false
	departing = false
	final_guard = false
	departure_time = 0
	rescued_ids.clear()
	checkpoint = Vector2(130,555)
	selected = "baby_one"
	plan.clear()
	pending_answer.clear()
	session_uses.clear()
	session_choices.clear()
	session_spoken = 0
	retry_count = 0
	camera_x = 0
	_layout_world()
	for boat in boats.values(): boat.reset_state()
	for friend in friends.values(): friend.reset_friend()
	player.reset_at(world.to_global(checkpoint))
	player.active = true
	player.set_process_unhandled_input(true)
	guard.configure(world.to_global(Vector2(1470,555)))
	guard.active = false
	scenery.completed = false
	_load_rescue()
	_enter_step()
	_status(tr2("Calabrija: Our friends missed the fiesta! Meet the little one by the lantern.","Calabrija: ¡Nuestros amigos se quedaron! Acércate al pequeño junto al farol."),8)

func _enter_step() -> void:
	current_screen = "game"
	step = rescued_ids.size()
	_new_context()
	_build_hud()

func _rescue(id: String) -> void:
	if id in rescued_ids or not playing or retrying: return
	rescued_ids.append(id)
	friends[id].follow_index = rescued_ids.size()-1
	if id=="baby_one": checkpoint = Vector2(450,555)
	elif id=="rabbit": checkpoint = Vector2(1320,555)
	else: checkpoint = Vector2(1935,555)
	_status(tr2("¡Hola! A friend joins you · ","¡Hola! Un amigo te acompaña · ")+str(rescued_ids.size())+"/3",4)
	plan.clear()
	controller.wait_here()
	_record_action()
	selected = "lupita" if id=="baby_one" else ("frida" if id=="rabbit" else "landing")
	_save_rescue()
	_enter_step()

func _in_cover() -> bool:
	if player.position.x<1050: return true
	for x in COVERS:
		if absf(player.position.x-x)<48 and player.is_on_floor(): return true
	return false

func _safe_planning() -> bool:
	return player.is_on_floor() and (_in_cover() or _aboard("lupita") or _aboard("frida") or _aboard("esperanza") or absf(player.position.x-1935)<65)

func _freeze_encounter(value: bool) -> void:
	frozen_encounter = value
	guard.set_physics_process(not value)
	for boat in boats.values(): boat.frozen = value

func _new_context() -> void:
	super._new_context()
	_freeze_encounter(false)

func _aboard(id: String) -> bool:
	var boat = boats[id]
	return player.is_on_floor() and absf(player.position.y-boat.position.y)<12 and absf(player.position.x-boat.position.x)<boat.width/2-8

func _destination(id: String) -> Vector2:
	if boats.has(id): return boats[id].position
	if friends.has(id): return friends[id].position
	match id:
		"garden": return Vector2(990,555)
		"reeds": return Vector2(1660,555)
		"island": return Vector2(1935,555)
		"landing": return Vector2(2480,555)
		"bridge": return Vector2(2850,555)
	return player.position

func _cue() -> Dictionary:
	if rescued_ids.is_empty(): return {"phrase":"Ven.","meaning":"Come here. Meet the baby at the lantern."}
	if selected=="rabbit" or selected=="reeds" or selected=="bridge": return {"phrase":"Mira allá. Luego, ven.","meaning":"Look over there. Then come. Ring the bell; cross while he investigates."}
	if selected=="frida": return {"phrase":"El pequeño está en Frida. Al bote.","meaning":"The little one is on Frida. Onto the boat. Use the garden island, or double-jump."}
	if boats.has(selected): return {"phrase":"Al bote: "+boats[selected].display_name+".","meaning":"Onto the named boat. Xochi waits for a safe boarding window."}
	return {"phrase":"Salta. Al puente.","meaning":"Jump. To the bridge. Swipe up again for a second jump."}

func submit_intent(intent: String, language := "es", source := "touch", expected_generation := -1) -> bool:
	if not playing or finished or retrying or departing or get_tree().paused: return false
	if expected_generation>=0 and expected_generation!=generation: return false
	if intent in ["lupita","frida","esperanza"]:
		selected = intent
		intent = "boat"
	_new_context()
	plan.clear()
	controller.wait_here()
	pending_answer = {"intent":intent,"language":language,"source":source,"assisted":true}
	if intent=="wait" or intent=="behind_boat":
		_record_action()
		_status(tr2("Espera. Xochi waits; reeds hide her from the crow.","Espera. Xochi espera; los juncos la ocultan del cuervo."),4)
		return true
	if intent=="distract":
		if player.position.x<900:
			_status(tr2("The bell is across the canal. Take La Lupita first.","La campana está al otro lado. Sube a La Lupita primero."),4)
			return false
		guard.distract("bell")
		bell_pulse = 1.5
		_record_action()
		_status(tr2("Mira allá! Calabrija rings. Go while he looks away.","¡Mira allá! Calabrija toca. Avanza mientras mira la campana."),4)
		return true
	if intent=="bridge": selected = "garden" if player.position.x<900 else ("reeds" if player.position.x<1750 else "bridge")
	if intent=="boat" and not boats.has(selected): selected = "lupita" if player.position.x<900 else ("frida" if player.position.x<2440 else "esperanza")
	if intent not in ["come","boat","bridge","jump","now"]:
		pending_answer.clear()
		return false
	_make_plan(selected)
	_status(tr2("Destination: ","Destino: ")+_name_for(selected)+tr2(". Swipe to take over.",". Desliza para tomar el control."),5)
	return true

func _make_plan(id: String) -> void:
	var x: float = player.position.x
	if _destination(id).x < x-100:
		_make_return_plan(id)
		return
	if id=="lupita" and _aboard("lupita"): id = "garden"
	if id=="frida" and _aboard("frida"): id = "landing"
	if x<500 and id!="baby_one":
		plan.append({"point":Vector2(450,555)})
		plan.append({"board":"lupita"})
		if id=="lupita": return
	if (x<900 or _aboard("lupita")) and id!="baby_one":
		plan.append({"ride":"lupita","near":Vector2(800,555)})
		plan.append({"point":Vector2(990,555),"jump":true})
	if id in ["baby_one","garden","rabbit","reeds"]:
		plan.append({"point":_destination(id)})
		return
	if x<1700 and id in ["frida","island","landing","bridge","esperanza"]:
		# A single direction is bounded by visible refuge points, not target_hidden gates.
		if x<1300: plan.append({"point":Vector2(1320,555)})
		plan.append({"point":Vector2(1660,555)})
	if x<1800 and id in ["frida","island","landing","bridge","esperanza"]:
		plan.append({"point":Vector2(1710,555)})
		plan.append({"point":Vector2(1935,555),"jump":true})
	if id=="island": return
	if x<2440 and not _aboard("frida"):
		plan.append({"board":"frida"})
	if id=="frida": return
	if x<2440:
		plan.append({"ride":"frida","near":Vector2(2300,530)})
		plan.append({"point":Vector2(2480,555),"jump":true})
	if id=="landing": return
	if x<2650: plan.append({"point":Vector2(2660,555)})
	plan.append({"point":Vector2(2850,555)})
	if id=="bridge": return
	plan.append({"point":Vector2(2970,555)})
	plan.append({"board":"esperanza"})

func _advance_plan(delta: float) -> void:
	if plan.is_empty(): return
	if controller.guiding: return
	if not player.is_on_floor(): return
	var segment: Dictionary = plan[0]
	if segment.has("ride"):
		if not _aboard(segment.ride):
			plan.clear()
			_guidance_failed("boat_left")
			return
		if boats[segment.ride].position.distance_to(segment.near)<5: plan.pop_front()
		return
	if segment.has("board"):
		var boat = boats[segment.board]
		if _aboard(segment.board):
			plan.pop_front()
			if plan.is_empty():
				_record_action()
				_recommend_destination()
			return
		# Depart only during a dwell, with a reachable landing through the jump.
		if absf(boat.position.x-player.position.x)>300 or boat.at_time(boat.clock).distance_to(boat.at_time(boat.clock+1.1))>3: return
		if controller.guide_to(boat.global_position,true): controller.moving_target = boat
		return
	var point: Vector2 = segment.point
	if player.position.distance_to(point)<12:
		plan.pop_front()
		if plan.is_empty():
			_record_action()
			_recommend_destination()
		return
	if not controller.guide_to(world.to_global(point),segment.get("jump",false)):
		plan.clear()

func _recommend_destination() -> void:
	if _aboard("lupita"): selected = "garden"
	elif player.position.x<1100 and player.position.x>850: selected = "rabbit"
	elif _aboard("frida"): selected = "landing"
	elif player.position.x>=2400 and player.position.x<2700: selected = "bridge"
	elif player.position.x>=2700: selected = "esperanza"
	_build_hud()

func _record_action() -> void:
	if pending_answer.is_empty(): return
	var answer := pending_answer.duplicate()
	pending_answer.clear()
	session_uses[answer.intent] = true
	if answer.source=="voice" and answer.language=="es": session_spoken += 1
	# Displayed translations make touch an assisted action, never proof of mastery.
	save.record(answer.intent,answer.source,answer.language,true)
	save.write_save()

func _manual_takeover() -> void:
	plan.clear()
	pending_answer.clear()
	super._manual_takeover()

func _guidance_failed(reason: String) -> void:
	plan.clear()
	pending_answer.clear()
	var message := tr2("Xochi stopped safely. Select a nearby lantern or boat and guide again.","Xochi se detuvo a salvo. Elige un farol o bote cercano y vuelve a guiar.")
	if reason=="not_ready": message = tr2("Release your swipe and land before giving a new plan.","Suelta el dedo y aterriza antes de dar otro plan.")
	elif reason=="boat_left": message = tr2("The boat will return. Wait by the lantern, then board again.","El bote volverá. Espera junto al farol y vuelve a subir.")
	_status(message,5)

func _retry() -> void:
	if retrying or not playing or finished or departing: return
	retrying = true
	retry_count += 1
	plan.clear()
	controller.cancel_guidance()
	pending_answer.clear()
	_new_context()
	player.active = false
	player.clear_input()
	guard.active = false
	_status(tr2("A splash, a breath. Your friends and song stay with you.","Un chapuzón, un respiro. Tus amigos y la canción siguen contigo."),4)
	await get_tree().create_timer(.48,false).timeout
	if retrying and playing and not finished: _finish_interrupted_retry()

func _finish_interrupted_retry() -> void:
	if not retrying: return
	retrying = false
	for boat in boats.values(): boat.reset_state()
	player.reset_at(world.to_global(checkpoint))
	player.active = true
	final_guard = checkpoint.x>=2440
	guard.configure(world.to_global(Vector2(2780 if final_guard else 1470,555)))
	guard.active = not rescued_ids.is_empty()
	_recommend_destination()

func _toggle_mic() -> void:
	if voice.listening or voice.requesting or voice.interpreting:
		voice.stop()
		_freeze_encounter(false)
		return
	if not _safe_planning():
		_status(tr2("Speak at a lantern, island, or aboard a boat. Touch works everywhere.","Habla junto a un farol, en la isla o a bordo. El tacto funciona en todas partes."),4)
		return
	super._toggle_mic()

func _type_guidance() -> void:
	if not _safe_planning():
		_status(tr2("Reach a refuge to type a plan.","Llega a un refugio para escribir."),4)
		return
	super._type_guidance()

func _hear() -> void:
	voice.speak_example("Ven" if rescued_ids.is_empty() else ("Al bote" if boats.has(selected) else ("Mira allá" if selected in ["rabbit","reeds","bridge"] else "Salta")))
	example_duck_time = 3.2
	_status(_cue().phrase,4)

func _meaning() -> void: _status(_cue().meaning,8)

func _name_for(id: String) -> String:
	if boats.has(id): return boats[id].display_name
	return {"baby_one":"Bebé · Ven","rabbit":"Rabbitbrije","garden":"Jardín","reeds":"Refugio","island":"Chinampa","landing":"Muelle","bridge":"Puente"}.get(id,id)

func _build_hud() -> void:
	if is_instance_valid(hud):
		ui.remove_child(hud)
		hud.queue_free()
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	var safe := _safe_rect()
	var left := maxf(65,safe.position.x+12)
	var width := safe.end.x-left-65
	var top := 18.0
	var header := PanelContainer.new()
	header.position = Vector2(left,top)
	header.size = Vector2(width-145,156)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override("panel",_style(Color(.025,.14,.16,.94),18))
	hud.add_child(header)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(column)
	progress_label = _label(tr2("Find our friends","Encuentra a nuestros amigos")+" · "+str(rescued_ids.size())+"/3 → Esperanza",22,GOLD)
	column.add_child(progress_label)
	phrase_label = _label(_cue().phrase,35,CREAM,true)
	column.add_child(phrase_label)
	story_label = _label(tr2("Selected: ","Destino: ")+_name_for(selected),22)
	column.add_child(story_label)
	var pause := _button(tr2("Pause","Pausa"),_pause)
	pause.name = "Pause"
	pause.position = Vector2(left+width-135,top)
	hud.add_child(pause)
	status_label = _label("",22)
	status_label.position = Vector2(left,185)
	status_label.size = Vector2(width,64)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var backing := Panel.new()
	backing.position = status_label.position-Vector2(8,3)
	backing.size = status_label.size+Vector2(16,6)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.add_theme_stylebox_override("panel",_style(Color(.025,.14,.16,.90),12))
	hud.add_child(backing)
	hud.add_child(status_label)
	var row := HBoxContainer.new()
	row.position = Vector2(left,get_viewport_rect().size.y-108)
	row.size = Vector2(width,90)
	row.add_theme_constant_override("separation",8)
	hud.add_child(row)
	hear_button = _button(tr2("Hear","Oír"),_hear)
	hear_button.name = "Hear"
	row.add_child(hear_button)
	mic_button = _button(tr2("Speak","Hablar"),_toggle_mic)
	mic_button.name = "Speak"
	row.add_child(mic_button)
	choice_buttons.clear()
	for spec in [[tr2("Guide","Guiar"),"come"],["Espera","wait"],["Mira allá","distract"]]:
		var button := _button(spec[0],func(): submit_intent(spec[1],"es","touch"),spec[1]=="come")
		button.name = "Action_"+spec[1]
		row.add_child(button)
		choice_buttons.append(button)
	row.add_child(_button("?",_meaning))
	markers.clear()
	for id in ["baby_one","lupita","garden","rabbit","reeds","island","frida","landing","bridge","esperanza"]:
		var marker := _button(_name_for(id),func():
			selected = id
			plan.clear()
			controller.wait_here()
			_new_context()
			_build_hud())
		marker.name = "Destination_"+id
		marker.custom_minimum_size = Vector2(112,50)
		marker.add_theme_font_size_override("font_size",19)
		hud.add_child(marker)
		markers[id] = marker
	_update_markers()
	_refresh_status()

func _update_markers() -> void:
	for id in markers:
		var marker: Button = markers[id]
		var point := world.get_global_transform_with_canvas()*_destination(id)
		marker.position = point+Vector2(-marker.size.x/2,-235 if boats.has(id) else -110)
		marker.visible = point.x>80 and point.x<get_viewport_rect().size.x-80 and id not in rescued_ids
		marker.modulate = Color("ffe09d") if selected==id else Color.WHITE

func _refresh_status() -> void:
	if is_instance_valid(status_label): status_label.text = status_text if not status_text.is_empty() else tr2("Tap a destination, then Guide. Swipe up twice to double-jump. Open-water tap: hyper-jump.","Elige un destino y pulsa Guide. Desliza arriba dos veces: doble salto. Toque libre: hipersalto.")

func _begin_departure() -> void:
	departing = true
	plan.clear()
	controller.wait_here()
	_new_context()
	guard.active = false
	player.clear_input()
	player.set_process_unhandled_input(false)
	boats.esperanza.departing = true
	_status(tr2("Everyone aboard Esperanza. ¡A la fiesta!","Todos a bordo de Esperanza. ¡A la fiesta!"),5)

func _finish() -> void:
	finished = true
	_save_rescue()
	friends_arrived = true
	current_screen = "ending"
	player.active = false
	player.clear_input()
	guard.active = false
	_new_context()
	scenery.completed = true
	save.write_save()
	if is_instance_valid(hud): hud.hide()
	var column := _center_card(800)
	_copy(column,"¡A la fiesta!",56,true)
	_copy(column,tr2("Two little ones, Rabbitbrije, and one brave friend.\nEsperanza carries everyone home.","Dos pequeños, Rabbitbrije y una amiga valiente.\nEsperanza los lleva a casa."),28)
	_copy(column,tr2("Spoken Spanish practice: ","Práctica oral en español: ")+str(session_spoken),23)
	column.add_child(_button(tr2("Play again","Jugar otra vez"),_start_journey,true))
	column.add_child(_button(tr2("Title","Inicio"),_show_menu))

func _save_rescue() -> void:
	var file := FileAccess.open(save.save_path+".rescue.tmp",FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({"version":1,"rescued":rescued_ids,"checkpoint":[checkpoint.x,checkpoint.y],"completed":finished}))
	file.flush()
	file.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(save.save_path+".rescue.tmp"),ProjectSettings.globalize_path(save.save_path+".rescue"))

func _load_rescue() -> void:
	var path: String = save.save_path+".rescue"
	if not FileAccess.file_exists(path): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version")!=1 or data.get("completed",false): return
	if not data.get("rescued") is Array or not data.get("checkpoint") is Array: return
	if data.checkpoint.size()!=2: return
	var valid_x := [130,450,990,1320,1660,1935,2480,2850]
	if data.checkpoint[0] not in valid_x or data.checkpoint[1]!=555: return
	for id in data.rescued:
		if id in friends and id not in rescued_ids:
			rescued_ids.append(id)
			friends[id].joined = true
			friends[id].follow_index = rescued_ids.size()-1
	checkpoint = Vector2(data.checkpoint[0],555)
	player.reset_at(world.to_global(checkpoint))
	final_guard = checkpoint.x>=2440
	guard.configure(world.to_global(Vector2(2780 if final_guard else 1470,555)))
	selected = "lupita" if checkpoint.x<900 else ("rabbit" if "rabbit" not in rescued_ids else ("frida" if "baby_two" not in rescued_ids else "bridge"))

func _show_intro() -> void:
	current_screen = "intro"
	var column := _center_card(930)
	_copy(column,tr2("The Trajinera Rescue","El rescate de las trajineras"),45,true)
	_copy(column,tr2("Two babies and Rabbitbrije missed the fiesta.
Find all three, then board Esperanza together.","Dos bebés y Rabbitbrije se quedaron atrás.
Encuentra a los tres y sube con ellos a Esperanza."),27)
	_copy(column,tr2("Tap a destination, then Guide—or move Xochi yourself.
Friends join when you reach them. Read the Spanish clues.","Elige un destino y pulsa Guiar, o mueve a Xochi tú.
Los amigos se unen cuando llegas. Lee las pistas en español."),25)
	_copy(column,tr2("La Lupita ferries you across. Frida carries a baby.
Hide in reeds. “Mira allá” sends Calabrija to the bell.","La Lupita te cruza. Frida lleva a un bebé.
Escóndete entre juncos. «Mira allá» llama a Calabrija a la campana."),25)
	_copy(column,tr2("Swipe and hold: move · Two upward swipes: double-jump
Tap open playfield: hyper-jump · Speak at safe refuges", "Desliza y mantén: moverte · Dos deslizamientos arriba: doble salto
Toque libre: hipersalto · Habla en los refugios"),22)
	var begin := _button(tr2("Let's find our friends","Busquemos a nuestros amigos"),_start_journey,true)
	begin.name = "StartJourney"
	column.add_child(begin)

func _make_return_plan(id: String) -> void:
	var x: float = player.position.x
	var destination := _destination(id)
	if x>3020: plan.append({"point":Vector2(2970,555),"jump":true})
	if x>2440 and destination.x<2440:
		for point in [2850.0,2660.0,2480.0]:
			if x>point+15: plan.append({"point":Vector2(point,555)})
		plan.append({"board":"frida"})
	if destination.x<2100 and (x>2020 or _aboard("frida")):
		plan.append({"ride":"frida","near":Vector2(2180,530)})
		plan.append({"point":Vector2(1935,555),"jump":true})
	if destination.x<1750 and x>1750:
		plan.append({"point":Vector2(1710,555),"jump":true})
	if destination.x<900:
		for point in [1660.0,1320.0,990.0]:
			if x>point+15: plan.append({"point":Vector2(point,555)})
		plan.append({"board":"lupita"})
		plan.append({"ride":"lupita","near":Vector2(600,555)})
		plan.append({"point":Vector2(450,555),"jump":true})
	elif destination.x<1750:
		for point in [1660.0,1320.0]:
			if x>point+15 and destination.x<point-15: plan.append({"point":Vector2(point,555)})
	if id not in boats: plan.append({"point":destination})
