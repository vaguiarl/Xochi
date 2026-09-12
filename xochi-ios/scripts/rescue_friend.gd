extends Node2D
## Rescue is a world event. Followers are visual companions, never extra targets.
signal rescued(friend_id: String)
var friend_id := "baby_one"
var joined := false
var leader: Node2D
var carrier: Node2D
var home := Vector2.ZERO
var follow_index := 0
var texture: Texture2D
var time := 0.0
var greeting := 0.0
var recovery := 0.0

func configure(id: String, at: Vector2, rabbit := false) -> void:
	friend_id = id
	home = at
	position = at
	texture = load("res://assets/companion/rabbitbrije.png" if rabbit else "res://assets/xochi.png")

func reset_friend() -> void:
	joined = false
	position = home
	greeting = 0

func _physics_process(delta: float) -> void:
	time += delta
	greeting = maxf(0,greeting-delta)
	if not is_instance_valid(leader): return
	if not joined:
		if is_instance_valid(carrier): global_position = carrier.global_position
		if leader.active and leader.is_on_floor() and leader.global_position.distance_to(global_position)<55:
			joined = true
			greeting = 1.4
			rescued.emit(friend_id)
	else:
		# Companions fly/hop along a visible trailing arc over water. They have no
		# collision/detection, so a child cannot silently strand the whole party.
		var target := leader.global_position + Vector2(-(follow_index+1)*34*leader.facing,-12)
		var distance := global_position.distance_to(target)
		recovery = move_toward(recovery,1.0 if distance>180 else 0.0,delta*2)
		global_position = global_position.move_toward(target,delta*maxf(240,distance*3))
	queue_redraw()

func _draw() -> void:
	var rabbit := friend_id == "rabbit"
	var height := 65.0 if rabbit else 48.0
	var width := height*texture.get_width()/texture.get_height()
	var hop := absf(sin(time*(7 if joined else 3)))*(12 if rabbit else 3)+greeting*12+recovery*36
	draw_texture_rect(texture,Rect2(-width/2,-height-hop,width,height),false)
	if not joined:
		draw_arc(Vector2(0,-5),29,PI,TAU,30,Color("efc580"),3,true)
	if greeting>0:
		draw_string(ThemeDB.fallback_font,Vector2(-22,-height-30),"¡Sí!",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("fff0d1"))
